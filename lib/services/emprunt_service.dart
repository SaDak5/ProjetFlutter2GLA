import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emprunt_model.dart';
import '../models/reservation_model.dart';

class EmpruntService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _empruntsCollection = 'emprunts';
  final String _reservationsCollection = 'reservations';
  final String _cataloguesCollection = 'catalogues';
  final String _usersCollection = 'users';
  
  // ========== EMPRUNTS ==========
  
  Stream<List<EmpruntModel>> streamMesEmprunts(String userId) {
    return _firestore
        .collection(_empruntsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateEmprunt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            EmpruntModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  Future<void> emprunter(String userId, String catalogueId, int nbExemplaires) async {
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final catalogueDoc = await transaction.get(catalogueRef);
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final catalogueData = catalogueDoc.data() as Map<String, dynamic>;
      
      final nbEmpruntsActifs = (userData['nbEmpruntsActifs'] ?? 0).toInt();
      final limiteEmprunts = (userData['limiteEmprunts'] ?? 5).toInt();
      final exemplairesDispo = (catalogueData['nbExemplairesDisponibles'] ?? 0).toInt();
      
      if (nbEmpruntsActifs >= limiteEmprunts) {
        throw Exception('Limite d\'emprunts atteinte');
      }
      if (exemplairesDispo < 1) {
        throw Exception('Plus d\'exemplaires disponibles');
      }
      
      final codeBarres = _genererCodeBarres();
      final dateRetourPrevu = DateTime.now().add(const Duration(days: 14));
      
      final emprunt = EmpruntModel(
        id: _firestore.collection(_empruntsCollection).doc().id,
        userId: userId,
        catalogueId: catalogueId,
        titre: catalogueData['titre'] ?? '',
        auteur: catalogueData['auteur'] ?? '',
        imageUrl: catalogueData['imageUrl'] ?? '',
        dateEmprunt: DateTime.now(),
        dateRetourPrevu: dateRetourPrevu,
        codeBarres: codeBarres,
      );
      
      transaction.set(_firestore.collection(_empruntsCollection).doc(emprunt.id), emprunt.toMap());
      transaction.update(catalogueRef, {'nbExemplairesDisponibles': exemplairesDispo - 1});
      transaction.update(userRef, {'nbEmpruntsActifs': nbEmpruntsActifs + 1});
    });
  }
  
  Future<void> retourner(String empruntId, String catalogueId) async {
    final empruntRef = _firestore.collection(_empruntsCollection).doc(empruntId);
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    
    await _firestore.runTransaction((transaction) async {
      final empruntDoc = await transaction.get(empruntRef);
      final catalogueDoc = await transaction.get(catalogueRef);
      
      final empruntData = empruntDoc.data() as Map<String, dynamic>;
      final catalogueData = catalogueDoc.data() as Map<String, dynamic>;
      
      final exemplairesDispo = (catalogueData['nbExemplairesDisponibles'] ?? 0).toInt();
      
      transaction.update(empruntRef, {
        'dateRetourEffectif': Timestamp.now(),
        'statut': StatusEmprunt.termine.toString(),
      });
      transaction.update(catalogueRef, {'nbExemplairesDisponibles': exemplairesDispo + 1});
    });
  }
  
  Future<void> prolonger(String empruntId) async {
    final empruntRef = _firestore.collection(_empruntsCollection).doc(empruntId);
    
    await _firestore.runTransaction((transaction) async {
      final empruntDoc = await transaction.get(empruntRef);
      final data = empruntDoc.data() as Map<String, dynamic>;
      
      final prolongations = (data['prolongations'] ?? 0).toInt();
      final dateRetourPrevu = (data['dateRetourPrevu'] as Timestamp).toDate();
      
      if (prolongations >= 2) {
        throw Exception('Prolongation maximale atteinte');
      }
      
      final nouvelleDate = dateRetourPrevu.add(const Duration(days: 14));
      
      transaction.update(empruntRef, {
        'dateRetourPrevu': Timestamp.fromDate(nouvelleDate),
        'prolongations': prolongations + 1,
      });
    });
  }
  
  String _genererCodeBarres() {
    return 'MC${DateTime.now().millisecondsSinceEpoch}${DateTime.now().microsecond}';
  }
  
  // ========== RÉSERVATIONS ==========
  
  Stream<List<ReservationModel>> streamMesReservations(String userId) {
    return _firestore
        .collection(_reservationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateReservation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  Future<void> reserver(String userId, String catalogueId) async {
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    
    await _firestore.runTransaction((transaction) async {
      final catalogueDoc = await transaction.get(catalogueRef);
      final catalogueData = catalogueDoc.data() as Map<String, dynamic>;
      
      final nbExemplaires = (catalogueData['nbExemplaires'] ?? 0).toInt();
      final nbExemplairesDispo = (catalogueData['nbExemplairesDisponibles'] ?? 0).toInt();
      final reservationsCount = (catalogueData['reservationsCount'] ?? 0).toInt();
      
      final position = nbExemplaires - nbExemplairesDispo + reservationsCount + 1;
      
      final reservation = ReservationModel(
        id: _firestore.collection(_reservationsCollection).doc().id,
        userId: userId,
        catalogueId: catalogueId,
        titre: catalogueData['titre'] ?? '',
        auteur: catalogueData['auteur'] ?? '',
        imageUrl: catalogueData['imageUrl'] ?? '',
        dateReservation: DateTime.now(),
        positionFile: position,
      );
      
      transaction.set(_firestore.collection(_reservationsCollection).doc(reservation.id), reservation.toMap());
      transaction.update(catalogueRef, {'reservationsCount': reservationsCount + 1});
    });
  }
  
  Future<void> annulerReservation(String reservationId, String catalogueId) async {
    await _firestore.collection(_reservationsCollection).doc(reservationId).delete();
  }
}
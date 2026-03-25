import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';
import '../models/catalogue_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reservationsCollection = 'reservations';
  final String _cataloguesCollection = 'catalogues';
  final String _usersCollection = 'users';
  
  // ========== STREAMS ==========
  
  /// Stream des réservations d'un utilisateur
  Stream<List<ReservationModel>> streamMesReservations(String userId) {
    return _firestore
        .collection(_reservationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateReservation', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  /// Stream des réservations en attente pour un catalogue
  Stream<List<ReservationModel>> streamReservationsParCatalogue(String catalogueId) {
    return _firestore
        .collection(_reservationsCollection)
        .where('catalogueId', isEqualTo: catalogueId)
        .where('statut', isEqualTo: 'enAttente')
        .orderBy('dateReservation')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  // ========== CRUD RÉSERVATIONS ==========
  
  /// Réserver un média
  Future<ReservationModel> reserver({
    required String userId,
    required String catalogueId,
    required String titre,
    required String auteur,
    required String imageUrl,
  }) async {
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    
    return await _firestore.runTransaction((transaction) async {
      final catalogueDoc = await transaction.get(catalogueRef);
      final userDoc = await transaction.get(userRef);
      
      if (!catalogueDoc.exists) throw Exception('Média introuvable');
      if (!userDoc.exists) throw Exception('Utilisateur introuvable');
      
      final catalogueData = catalogueDoc.data() as Map<String, dynamic>;
      final userData = userDoc.data() as Map<String, dynamic>;
      
      final nbExemplaires = (catalogueData['nbExemplaires'] ?? 1).toInt();
      final nbExemplairesDispo = (catalogueData['nbExemplairesDisponibles'] ?? 0).toInt();
      final reservationsCount = (catalogueData['reservationsCount'] ?? 0).toInt();
      
      // Vérifier si le média est déjà réservé par l'utilisateur
      final existingReservation = await _firestore
          .collection(_reservationsCollection)
          .where('userId', isEqualTo: userId)
          .where('catalogueId', isEqualTo: catalogueId)
          .where('statut', isEqualTo: 'enAttente')
          .get();
      
      if (existingReservation.docs.isNotEmpty) {
        throw Exception('Vous avez déjà une réservation en cours pour ce média');
      }
      
      // Vérifier si l'utilisateur a déjà emprunté ce média
      final existingEmprunt = await _firestore
          .collection('emprunts')
          .where('userId', isEqualTo: userId)
          .where('catalogueId', isEqualTo: catalogueId)
          .where('statut', isEqualTo: 'enCours')
          .get();
      
      if (existingEmprunt.docs.isNotEmpty) {
        throw Exception('Vous avez déjà ce média en votre possession');
      }
      
      // Calculer la position dans la file d'attente
      final position = nbExemplaires - nbExemplairesDispo + reservationsCount + 1;
      
      final reservation = ReservationModel(
        id: _firestore.collection(_reservationsCollection).doc().id,
        userId: userId,
        catalogueId: catalogueId,
        titre: titre,
        auteur: auteur,
        imageUrl: imageUrl,
        dateReservation: DateTime.now(),
        statut: StatusReservation.enAttente,
        positionFile: position,
      );
      
      // Sauvegarder la réservation
      transaction.set(
        _firestore.collection(_reservationsCollection).doc(reservation.id),
        reservation.toMap()
      );
      
      // Incrémenter le compteur de réservations
      transaction.update(catalogueRef, {
        'reservationsCount': reservationsCount + 1,
      });
      
      return reservation;
    });
  }
  
  /// Annuler une réservation
  Future<void> annulerReservation(String reservationId, String catalogueId) async {
    final reservationRef = _firestore.collection(_reservationsCollection).doc(reservationId);
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    
    await _firestore.runTransaction((transaction) async {
      final reservationDoc = await transaction.get(reservationRef);
      if (!reservationDoc.exists) throw Exception('Réservation introuvable');
      
      final reservationData = reservationDoc.data() as Map<String, dynamic>;
      final catalogueDoc = await transaction.get(catalogueRef);
      final catalogueData = catalogueDoc.data() as Map<String, dynamic>;
      
      final reservationsCount = (catalogueData['reservationsCount'] ?? 0).toInt();
      
      transaction.update(reservationRef, {
        'statut': StatusReservation.annulee.toString(),
      });
      
      transaction.update(catalogueRef, {
        'reservationsCount': reservationsCount - 1,
      });
      
      // Recalculer les positions des autres réservations
      await _recalculerPositions(catalogueId);
    });
  }
  
  /// Recalculer les positions dans la file d'attente
  Future<void> _recalculerPositions(String catalogueId) async {
    final reservations = await _firestore
        .collection(_reservationsCollection)
        .where('catalogueId', isEqualTo: catalogueId)
        .where('statut', isEqualTo: 'enAttente')
        .orderBy('dateReservation')
        .get();
    
    int position = 1;
    for (var doc in reservations.docs) {
      await doc.reference.update({'positionFile': position});
      position++;
    }
  }
  
  /// Notifier le prochain utilisateur quand un média devient disponible
  Future<void> notifierProchainReservant(String catalogueId) async {
    final reservations = await _firestore
        .collection(_reservationsCollection)
        .where('catalogueId', isEqualTo: catalogueId)
        .where('statut', isEqualTo: 'enAttente')
        .orderBy('dateReservation')
        .limit(1)
        .get();
    
    if (reservations.docs.isNotEmpty) {
      final reservation = reservations.docs.first;
      final userId = reservation.data()['userId'] as String;
      
      // Mettre à jour le statut de la réservation
      await reservation.reference.update({
        'statut': StatusReservation.disponible.toString(),
      });
      
      // TODO: Envoyer une notification push à l'utilisateur
      print('Notification à envoyer à l\'utilisateur $userId: Le média est disponible');
    }
  }
  
  /// Récupérer le nombre de réservations pour un catalogue
  Future<int> getNombreReservations(String catalogueId) async {
    final snapshot = await _firestore
        .collection(_reservationsCollection)
        .where('catalogueId', isEqualTo: catalogueId)
        .where('statut', isEqualTo: 'enAttente')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
  
  /// Vérifier si l'utilisateur a déjà réservé un média
  Future<bool> aDejaReserve(String userId, String catalogueId) async {
    final snapshot = await _firestore
        .collection(_reservationsCollection)
        .where('userId', isEqualTo: userId)
        .where('catalogueId', isEqualTo: catalogueId)
        .where('statut', isEqualTo: 'enAttente')
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
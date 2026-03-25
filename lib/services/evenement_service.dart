import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evenement_model.dart';

class EvenementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'evenements';
  
  // ========== STREAMS ==========
  
  Stream<List<EvenementModel>> streamEvenements() {
    return _firestore
        .collection(_collectionName)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            EvenementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  // ========== RECHERCHES ==========
  
  Stream<List<EvenementModel>> rechercherParTitre(String recherche) {
    if (recherche.isEmpty) return streamEvenements();
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
          final results = <EvenementModel>[];
          final search = recherche.toLowerCase();
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['titre'] ?? '').toLowerCase().contains(search)) {
              results.add(EvenementModel.fromMap(data, doc.id));
            }
          }
          return results;
        });
  }
  
  Stream<List<EvenementModel>> rechercherParType(String type) {
    if (type.isEmpty) return streamEvenements();
    return _firestore
        .collection(_collectionName)
        .where('type', isEqualTo: type)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            EvenementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  Future<EvenementModel?> getEvenementById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return EvenementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // ========== CRUD ==========
  
  Future<void> ajouterEvenement(EvenementModel evenement) async {
    await _firestore.collection(_collectionName).doc(evenement.id).set(evenement.toMap());
  }
  
  Future<void> modifierEvenement(EvenementModel evenement) async {
    await _firestore.collection(_collectionName).doc(evenement.id).update(evenement.toMap());
  }
  
  Future<void> supprimerEvenement(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
  
  // ========== RÉSERVATIONS ==========
  
  Future<void> reserverPlaces(String evenementId, int nombrePlaces) async {
    final evenementRef = _firestore.collection(_collectionName).doc(evenementId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(evenementRef);
      final data = snapshot.data() as Map<String, dynamic>;
      
      final placesReservees = (data['placesReservees'] ?? 0).toInt();
      final nombrePlacesTotal = (data['nombrePlaces'] ?? 0).toInt();
      
      if (placesReservees + nombrePlaces > nombrePlacesTotal) {
        throw Exception('Plus assez de places disponibles');
      }
      
      transaction.update(evenementRef, {
        'placesReservees': placesReservees + nombrePlaces,
      });
    });
  }
  
  Future<void> annulerReservation(String evenementId, int nombrePlaces) async {
    final evenementRef = _firestore.collection(_collectionName).doc(evenementId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(evenementRef);
      final data = snapshot.data() as Map<String, dynamic>;
      
      final placesReservees = (data['placesReservees'] ?? 0).toInt();
      
      transaction.update(evenementRef, {
        'placesReservees': (placesReservees - nombrePlaces).clamp(0, placesReservees),
      });
    });
  }


  
}
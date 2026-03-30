import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evenement_model.dart';

class EvenementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'evenements';
  final String _usersCollection = 'users';
  
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
    if (type.isEmpty || type == 'Tous') return streamEvenements();
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
      print('❌ Erreur getEvenementById: $e');
      return null;
    }
  }
  
  // ========== CRUD ==========
  
  Future<void> ajouterEvenement(EvenementModel evenement) async {
    try {
      await _firestore.collection(_collectionName).doc(evenement.id).set(evenement.toMap());
      print('✅ Événement ajouté: ${evenement.titre}');
    } catch (e) {
      print('❌ Erreur ajout événement: $e');
      throw Exception('Erreur lors de l\'ajout: $e');
    }
  }
  
  Future<void> modifierEvenement(EvenementModel evenement) async {
    try {
      await _firestore.collection(_collectionName).doc(evenement.id).update(evenement.toMap());
      print('✅ Événement modifié: ${evenement.titre}');
    } catch (e) {
      print('❌ Erreur modification événement: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }
  
  Future<void> supprimerEvenement(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      print('✅ Événement supprimé: $id');
    } catch (e) {
      print('❌ Erreur suppression événement: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
  
  // ========== RÉSERVATIONS ==========
  
  Future<void> reserverPlaces(String evenementId, int nombrePlaces, String userId) async {
    final evenementRef = _firestore.collection(_collectionName).doc(evenementId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(evenementRef);
      
      if (!snapshot.exists) {
        throw Exception('Événement non trouvé');
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      
      final placesReservees = (data['placesReservees'] ?? 0).toInt();
      final nombrePlacesTotal = (data['nombrePlaces'] ?? 0).toInt();
      
      // Récupérer les réservations existantes
      Map<String, int> reservations = {};
      final reservationsData = data['reservations'];
      if (reservationsData != null && reservationsData is Map) {
        reservationsData.forEach((key, value) {
          reservations[key.toString()] = (value as num).toInt();
        });
      }
      
      // Vérifier les places disponibles
      if (placesReservees + nombrePlaces > nombrePlacesTotal) {
        throw Exception('Plus assez de places disponibles');
      }
      
      // Mettre à jour les réservations
      final placesActuelles = reservations[userId] ?? 0;
      reservations[userId] = placesActuelles + nombrePlaces;
      
      // Mettre à jour l'événement
      transaction.update(evenementRef, {
        'placesReservees': placesReservees + nombrePlaces,
        'reservations': reservations,
      });
      
      print('✅ Réservation effectuée: $nombrePlaces place(s) pour $userId');
    });
  }
  
  Future<void> annulerReservation(String evenementId, int nombrePlaces, String userId) async {
    final evenementRef = _firestore.collection(_collectionName).doc(evenementId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(evenementRef);
      
      if (!snapshot.exists) {
        throw Exception('Événement non trouvé');
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      
      final placesReservees = (data['placesReservees'] ?? 0).toInt();
      
      // Récupérer les réservations existantes
      Map<String, int> reservations = {};
      final reservationsData = data['reservations'];
      if (reservationsData != null && reservationsData is Map) {
        reservationsData.forEach((key, value) {
          reservations[key.toString()] = (value as num).toInt();
        });
      }
      
      final placesActuelles = reservations[userId] ?? 0;
      
      if (placesActuelles < nombrePlaces) {
        throw Exception('Vous n\'avez pas assez de places réservées');
      }
      
      final nouvellesPlaces = placesActuelles - nombrePlaces;
      
      if (nouvellesPlaces <= 0) {
        // Supprimer complètement la réservation
        reservations.remove(userId);
      } else {
        // Mettre à jour le nombre de places
        reservations[userId] = nouvellesPlaces;
      }
      
      // Mettre à jour l'événement
      transaction.update(evenementRef, {
        'placesReservees': placesReservees - nombrePlaces,
        'reservations': reservations,
      });
      
      print('✅ Annulation effectuée: $nombrePlaces place(s) pour $userId');
    });
  }
  
  // ========== RÉCUPÉRATION DES PARTICIPANTS AVEC DÉTAILS ==========
  
  Future<List<Map<String, dynamic>>> getParticipantsAvecDetails(String evenementId) async {
    try {
      final evenement = await getEvenementById(evenementId);
      if (evenement == null) return [];
      
      final List<Map<String, dynamic>> participants = [];
      
      for (var entry in evenement.reservations.entries) {
        final userId = entry.key;
        final nbPlaces = entry.value;
        
        // Récupérer les détails de l'utilisateur
        final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          participants.add({
            'id': userId,
            'nom': userData['nom'] ?? '',
            'prenom': userData['prenom'] ?? '',
            'email': userData['email'] ?? '',
            'nbPlaces': nbPlaces,
          });
        } else {
          participants.add({
            'id': userId,
            'nom': 'Utilisateur inconnu',
            'prenom': '',
            'email': '',
            'nbPlaces': nbPlaces,
          });
        }
      }
      
      return participants;
    } catch (e) {
      print('❌ Erreur getParticipantsAvecDetails: $e');
      return [];
    }
  }
}
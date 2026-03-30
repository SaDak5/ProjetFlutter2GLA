import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/evenement_model.dart';
import '../services/evenement_service.dart';

class EvenementController extends ChangeNotifier {
  final EvenementService _service = EvenementService();
  
  List<EvenementModel> _evenements = [];
  bool _chargement = false;
  String? _erreur;
  List<Map<String, dynamic>> _participantsDetails = [];
  
  List<EvenementModel> get evenements => _evenements;
  bool get enChargement => _chargement;
  String? get erreur => _erreur;
  List<Map<String, dynamic>> get participantsDetails => _participantsDetails;
  Stream<List<EvenementModel>> get fluxEvenements => _service.streamEvenements();
  
  // ========== RECHERCHES ==========
  
  Future<void> reinitialiserRecherche() async {
    _enChargement(true);
    try {
      _evenements = await _service.streamEvenements().first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParTitre(String titre) async {
    _enChargement(true);
    try {
      _evenements = await _service.rechercherParTitre(titre).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParType(String type) async {
    _enChargement(true);
    try {
      _evenements = await _service.rechercherParType(type).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  // ========== CRUD ==========
  
  Future<bool> ajouterEvenement({
    required String titre,
    required String description,
    required DateTime date,
    required String lieu,
    required String adresse,
    required int nombrePlaces,
    required double prix,
    required String type,
    File? image,
    bool estGratuit = false,
  }) async {
    _enChargement(true);
    try {
      if (titre.isEmpty) throw Exception('Titre requis');
      if (lieu.isEmpty) throw Exception('Lieu requis');
      if (nombrePlaces <= 0) throw Exception('Nombre de places invalide');
      if (prix < 0) throw Exception('Prix invalide');
      
      String imageBase64 = '';
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }
      
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final nouvelEvenement = EvenementModel(
        id: id,
        titre: titre.trim(),
        description: description.trim(),
        imageBase64: imageBase64,
        date: date,
        lieu: lieu.trim(),
        adresse: adresse.trim(),
        nombrePlaces: nombrePlaces,
        placesReservees: 0,
        prix: prix,
        type: type,
        estGratuit: estGratuit,
        dateCreation: DateTime.now(),
        reservations: {},
      );
      
      await _service.ajouterEvenement(nouvelEvenement);
      _evenements.insert(0, nouvelEvenement);
      _erreur = null;
      notifyListeners();
      return true;
      
    } catch (e) {
      _erreur = e.toString();
      print('❌ Erreur ajout événement: $e');
      notifyListeners();
      return false;
    } finally {
      _enChargement(false);
    }
  }
  
  Future<bool> modifierEvenement(EvenementModel evenement) async {
    _enChargement(true);
    try {
      if (evenement.titre.isEmpty) throw Exception('Titre requis');
      if (evenement.lieu.isEmpty) throw Exception('Lieu requis');
      if (evenement.nombrePlaces <= 0) throw Exception('Nombre de places invalide');
      
      await _service.modifierEvenement(evenement);
      
      final index = _evenements.indexWhere((e) => e.id == evenement.id);
      if (index != -1) {
        _evenements[index] = evenement;
        notifyListeners();
      }
      
      _erreur = null;
      return true;
      
    } catch (e) {
      _erreur = e.toString();
      print('❌ Erreur modification événement: $e');
      notifyListeners();
      return false;
    } finally {
      _enChargement(false);
    }
  }
  
  Future<bool> supprimerEvenement(String id) async {
    _enChargement(true);
    try {
      await _service.supprimerEvenement(id);
      _evenements.removeWhere((e) => e.id == id);
      _erreur = null;
      notifyListeners();
      return true;
    } catch (e) {
      _erreur = e.toString();
      print('❌ Erreur suppression événement: $e');
      notifyListeners();
      return false;
    } finally {
      _enChargement(false);
    }
  }
  
  // ========== RÉSERVATIONS ==========
  
  Future<bool> reserverPlaces(String evenementId, int nombrePlaces, String userId) async {
    _enChargement(true);
    try {
      if (nombrePlaces <= 0) throw Exception('Nombre de places invalide');
      if (userId.isEmpty) throw Exception('Utilisateur non identifié');
      
      print('🔨 Réservation: evenementId=$evenementId, nbPlaces=$nombrePlaces, userId=$userId');
      
      await _service.reserverPlaces(evenementId, nombrePlaces, userId);
      
      // Mettre à jour l'événement dans la liste locale
      final updated = await _service.getEvenementById(evenementId);
      if (updated != null) {
        final index = _evenements.indexWhere((e) => e.id == evenementId);
        if (index != -1) {
          _evenements[index] = updated;
          notifyListeners();
        }
      }
      
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      print('❌ Erreur reservation: $e');
      notifyListeners();
      return false;
    } finally {
      _enChargement(false);
    }
  }
  
  Future<bool> annulerReservation(String evenementId, int nombrePlaces, String userId) async {
    _enChargement(true);
    try {
      if (nombrePlaces <= 0) throw Exception('Nombre de places invalide');
      if (userId.isEmpty) throw Exception('Utilisateur non identifié');
      
      print('🔨 Annulation: evenementId=$evenementId, nbPlaces=$nombrePlaces, userId=$userId');
      
      await _service.annulerReservation(evenementId, nombrePlaces, userId);
      
      // Mettre à jour l'événement dans la liste locale
      final updated = await _service.getEvenementById(evenementId);
      if (updated != null) {
        final index = _evenements.indexWhere((e) => e.id == evenementId);
        if (index != -1) {
          _evenements[index] = updated;
          notifyListeners();
        }
      }
      
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      print('❌ Erreur annulation: $e');
      notifyListeners();
      return false;
    } finally {
      _enChargement(false);
    }
  }
  
  // ========== RÉCUPÉRATION DES PARTICIPANTS ==========
  
  Future<void> chargerParticipants(String evenementId) async {
    try {
      _participantsDetails = await _service.getParticipantsAvecDetails(evenementId);
      print('✅ ${_participantsDetails.length} participants chargés');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement participants: $e');
      _participantsDetails = [];
      notifyListeners();
    }
  }
  
  // ========== UTILITAIRES ==========
  
  void _enChargement(bool loading) {
    _chargement = loading;
    notifyListeners();
  }
  
  void effacerErreur() {
    _erreur = null;
    notifyListeners();
  }
  
  void reinitialiserParticipants() {
    _participantsDetails = [];
    notifyListeners();
  }
  
  // Méthodes pour la vue
  bool utilisateurAReserve(String evenementId, String userId) {
    final evenement = _evenements.firstWhere((e) => e.id == evenementId, orElse: () => EvenementModel(
      id: '', titre: '', description: '', imageBase64: '', date: DateTime.now(),
      lieu: '', adresse: '', nombrePlaces: 0, prix: 0, type: '', dateCreation: DateTime.now(),
    ));
    return evenement.aReserve(userId);
  }
  
  int getPlacesReserveesUtilisateur(String evenementId, String userId) {
    final evenement = _evenements.firstWhere((e) => e.id == evenementId, orElse: () => EvenementModel(
      id: '', titre: '', description: '', imageBase64: '', date: DateTime.now(),
      lieu: '', adresse: '', nombrePlaces: 0, prix: 0, type: '', dateCreation: DateTime.now(),
    ));
    return evenement.getPlacesReserveesByUser(userId);
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/catalogue_model.dart';
import '../services/catalogue_service.dart';

class CatalogueController extends ChangeNotifier {
  final CatalogueService _service = CatalogueService();
  
  List<CatalogueModel> _catalogues = [];
  bool _chargement = false;
  String? _erreur;
  
  List<CatalogueModel> get catalogues => _catalogues;
  bool get enChargement => _chargement;
  String? get erreur => _erreur;
  Stream<List<CatalogueModel>> get fluxCatalogues => _service.streamCatalogues();
  
  // ========== RECHERCHES ==========
  
  Future<void> reinitialiserRecherche() async {
    _enChargement(true);
    try {
      _catalogues = await _service.streamCatalogues().first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParNom(String nom) async {
    _enChargement(true);
    try {
      _catalogues = await _service.rechercherParNom(nom).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParAuteur(String auteur) async {
    _enChargement(true);
    try {
      _catalogues = await _service.rechercherParAuteur(auteur).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParPrix(double min, double max) async {
    _enChargement(true);
    try {
      _catalogues = await _service.rechercherParPrix(min, max).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  Future<void> rechercherParNomOuAuteur(String texte) async {
    _enChargement(true);
    try {
      _catalogues = await _service.rechercherParNomOuAuteur(texte).first;
      _erreur = null;
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur: $e';
      notifyListeners();
    } finally {
      _enChargement(false);
    }
  }
  
  // ========== CRUD AVEC nbExemplaires ==========
  
  Future<bool> ajouterCatalogue({
    required String nom,
    required String description,
    required String auteur,
    required double prix,
    File? image,
    bool estDisponible = true,
    required String categorie,
    required int nbExemplaires,  // 👈 AJOUTER
  }) async {
    try {
      if (nom.isEmpty) throw Exception('Nom requis');
      if (auteur.isEmpty) throw Exception('Auteur requis');
      if (prix <= 0) throw Exception('Prix invalide');
      if (categorie.isEmpty) throw Exception('Catégorie requise');
      if (nbExemplaires <= 0) throw Exception('Nombre d\'exemplaires invalide');
      
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      String imageBase64 = '';
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }
      
      final nouveau = CatalogueModel(
        id: id,
        nom: nom.trim(),
        description: description.trim(),
        auteur: auteur.trim(),
        prix: prix,
        imageBase64: imageBase64,
        dateCreation: DateTime.now(),
        estDisponible: estDisponible,
        categorie: categorie,
        nbExemplaires: nbExemplaires,           // 👈 AJOUTER
        nbExemplairesDisponibles: nbExemplaires, // 👈 AJOUTER (au début tous disponibles)
      );
      
      await _service.ajouterCatalogue(nouveau);
      _catalogues.insert(0, nouveau);
      notifyListeners();
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> modifierCatalogue(CatalogueModel catalogue) async {
    try {
      if (catalogue.nom.isEmpty) throw Exception('Nom requis');
      if (catalogue.auteur.isEmpty) throw Exception('Auteur requis');
      if (catalogue.prix <= 0) throw Exception('Prix invalide');
      if (catalogue.categorie.isEmpty) throw Exception('Catégorie requise');
      if (catalogue.nbExemplaires <= 0) throw Exception('Nombre d\'exemplaires invalide');
      
      await _service.modifierCatalogue(catalogue);
      
      final index = _catalogues.indexWhere((c) => c.id == catalogue.id);
      if (index != -1) {
        _catalogues[index] = catalogue;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> supprimerCatalogue(String id) async {
    try {
      await _service.supprimerCatalogue(id);
      _catalogues.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // ========== GESTION DES EXEMPLAIRES ==========
  
  Future<bool> decrementerExemplaires(String catalogueId) async {
    try {
      await _service.decrementerExemplaires(catalogueId);
      
      // Mettre à jour la liste locale
      final index = _catalogues.indexWhere((c) => c.id == catalogueId);
      if (index != -1) {
        final item = _catalogues[index];
        final updated = item.copyWith(
          nbExemplairesDisponibles: item.nbExemplairesDisponibles - 1,
        );
        _catalogues[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> incrementerExemplaires(String catalogueId) async {
    try {
      await _service.incrementerExemplaires(catalogueId);
      
      // Mettre à jour la liste locale
      final index = _catalogues.indexWhere((c) => c.id == catalogueId);
      if (index != -1) {
        final item = _catalogues[index];
        final updated = item.copyWith(
          nbExemplairesDisponibles: item.nbExemplairesDisponibles + 1,
        );
        _catalogues[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<int> getNbExemplairesDisponibles(String catalogueId) async {
    return await _service.getNbExemplairesDisponibles(catalogueId);
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
}
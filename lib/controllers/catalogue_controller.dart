import 'dart:async';
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
  StreamSubscription? _subscription;

  List<CatalogueModel> get catalogues => _catalogues;
  bool get enChargement => _chargement;
  String? get erreur => _erreur;

  void ecouterCatalogues() {
    _subscription?.cancel();
    _chargement = true;
    notifyListeners();
    _subscription = _service.streamCatalogues().listen(
      (liste) {
        _catalogues = liste;
        _chargement = false;
        _erreur = null;
        notifyListeners();
      },
      onError: (e) {
        _erreur = e.toString();
        _chargement = false;
        notifyListeners();
      },
    );
  }

  Future<void> reinitialiserRecherche() async {
    ecouterCatalogues();
  }

  Future<void> rechercherParNom(String nom) async {
    _subscription?.cancel();
    _chargement = true;
    notifyListeners();
    _subscription = _service.rechercherParNom(nom).listen(
      (liste) {
        _catalogues = liste;
        _chargement = false;
        _erreur = null;
        notifyListeners();
      },
      onError: (e) {
        _erreur = e.toString();
        _chargement = false;
        notifyListeners();
      },
    );
  }

  Future<void> rechercherParAuteur(String auteur) async {
    _subscription?.cancel();
    _chargement = true;
    notifyListeners();
    _subscription = _service.rechercherParAuteur(auteur).listen(
      (liste) {
        _catalogues = liste;
        _chargement = false;
        _erreur = null;
        notifyListeners();
      },
      onError: (e) {
        _erreur = e.toString();
        _chargement = false;
        notifyListeners();
      },
    );
  }

  Future<void> rechercherParNomOuAuteur(String texte) async {
    _subscription?.cancel();
    _chargement = true;
    notifyListeners();
    _subscription = _service.rechercherParNomOuAuteur(texte).listen(
      (liste) {
        _catalogues = liste;
        _chargement = false;
        _erreur = null;
        notifyListeners();
      },
      onError: (e) {
        _erreur = e.toString();
        _chargement = false;
        notifyListeners();
      },
    );
  }

  Future<bool> ajouterCatalogue({
    required String nom,
    required String description,
    required String auteur,
    File? image,
    bool estDisponible = true,
    required String categorie,
    required int nbExemplairesDisponibles,
  }) async {
    try {
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
        imageBase64: imageBase64,
        dateCreation: DateTime.now(),
        estDisponible: estDisponible,
        categorie: categorie,
        nbExemplairesDisponibles: nbExemplairesDisponibles,
      );
      await _service.ajouterCatalogue(nouveau);
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifierCatalogue(CatalogueModel catalogue) async {
    try {
      await _service.modifierCatalogue(catalogue);
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
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> decrementerExemplaires(String catalogueId, int nombreEmprunte) async {
    try {
      await _service.decrementerExemplaires(catalogueId, nombreEmprunte);
      return true;
    } catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> incrementerExemplaires(String catalogueId, int nombreRetourne) async {
    try {
      await _service.incrementerExemplaires(catalogueId, nombreRetourne);
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

  void effacerErreur() {
    _erreur = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
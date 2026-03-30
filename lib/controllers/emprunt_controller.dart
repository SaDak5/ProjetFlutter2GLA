import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emprunt_model.dart';
import '../services/emprunt_service.dart';

class EmpruntController extends ChangeNotifier {
  final EmpruntService _service = EmpruntService();

  List<EmpruntModel> _mesEmprunts = [];
  List<EmpruntModel> _tousLesEmprunts = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<EmpruntModel> get mesEmprunts => _mesEmprunts;
  List<EmpruntModel> get tousLesEmprunts => _tousLesEmprunts;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // =========================
  // MES EMPRUNTS (USER)
  // =========================
  void chargerMesEmprunts(String userId) {
    if (userId.isEmpty) return;

    _setLoading(true);

    _service.streamMesEmprunts(userId).listen(
      (emprunts) {
        _mesEmprunts = emprunts;
        _error = null;
        _setLoading(false);
      },
      onError: (error) {
        _error = error.toString();
        _setLoading(false);
      },
    );
  }

  Future<void> rechargerMesEmprunts(String userId) async {
    if (userId.isEmpty) return;

    _setLoading(true);

    try {
      _mesEmprunts = await _service.streamMesEmprunts(userId).first;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // TOUS LES EMPRUNTS (GLOBAL)
  // =========================
  // =========================
// TOUS LES EMPRUNTS (GLOBAL)
// =========================
void chargerTousLesEmprunts() {
  _setLoading(true);

  // Utilisation du stream pour avoir les mises à jour en temps réel (ex: quand un retour est fait)
  _service.streamTousLesEmprunts().listen(
    (emprunts) {
      _tousLesEmprunts = emprunts;
      _error = null;
      _isLoading = false; // On passe par la variable pour éviter un notifyListeners en boucle ici
      notifyListeners();
    },
    onError: (error) {
      _error = error.toString();
      _setLoading(false);
    },
  );
}

  // =========================
  // EMPRUNTER
  // =========================
  Future<bool> emprunterAvecDate(
      String userId,
      String catalogueId,
      int nbExemplaires,
      DateTime dateRetour) async {
    _setLoading(true);

    try {
      await _service.emprunterAvecDate(
          userId, catalogueId, nbExemplaires, dateRetour);

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // RETOURNER
  // =========================
  Future<bool> retourner(
      String empruntId,
      String catalogueId,
      int nbExemplairesARendre) async {
    _setLoading(true);

    try {
      await _service.retourner(
          empruntId, catalogueId, nbExemplairesARendre);

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // UTIL
  // =========================
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
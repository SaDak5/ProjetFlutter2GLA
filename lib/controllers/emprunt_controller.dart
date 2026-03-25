import 'package:flutter/material.dart';
import '../models/emprunt_model.dart';
import '../models/reservation_model.dart';
import '../services/emprunt_service.dart';

class EmpruntController extends ChangeNotifier {
  final EmpruntService _service = EmpruntService();
  
  List<EmpruntModel> _mesEmprunts = [];
  List<ReservationModel> _mesReservations = [];
  bool _isLoading = false;
  String? _error;
  
  List<EmpruntModel> get mesEmprunts => _mesEmprunts;
  List<ReservationModel> get mesReservations => _mesReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> chargerMesEmprunts(String userId) async {
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
  
  Future<bool> emprunter(String userId, String catalogueId, int nbExemplaires) async {
    _setLoading(true);
    try {
      await _service.emprunter(userId, catalogueId, nbExemplaires);
      await chargerMesEmprunts(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> retourner(String empruntId, String catalogueId) async {
    _setLoading(true);
    try {
      await _service.retourner(empruntId, catalogueId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> prolonger(String empruntId) async {
    _setLoading(true);
    try {
      await _service.prolonger(empruntId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> reserver(String userId, String catalogueId) async {
    _setLoading(true);
    try {
      await _service.reserver(userId, catalogueId);
      await chargerMesReservations(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
 // Dans emprunt_controller.dart
// Remplacer la méthode annulerReservation par celle-ci :

Future<bool> annulerReservation(String reservationId, String catalogueId) async {
  _setLoading(true);
  try {
    await _service.annulerReservation(reservationId, catalogueId);
    // Recharger les réservations
    if (_mesReservations.isNotEmpty) {
      await chargerMesReservations(_mesReservations.first.userId);
    }
    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _setLoading(false);
  }
}
  
  Future<void> chargerMesReservations(String userId) async {
    _setLoading(true);
    try {
      _mesReservations = await _service.streamMesReservations(userId).first;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
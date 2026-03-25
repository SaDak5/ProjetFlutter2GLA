import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class ReservationController extends ChangeNotifier {
  final ReservationService _service = ReservationService();
  
  List<ReservationModel> _mesReservations = [];
  bool _isLoading = false;
  String? _error;
  
  List<ReservationModel> get mesReservations => _mesReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<List<ReservationModel>> Function(String userId) get fluxMesReservations => _service.streamMesReservations;
  
  // ========== CHARGEMENT ==========
  
  Future<void> chargerMesReservations(String userId) async {
    _setLoading(true);
    try {
      _mesReservations = await _service.streamMesReservations(userId).first;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // ========== RÉSERVATION ==========
  
  Future<bool> reserver({
    required String userId,
    required String catalogueId,
    required String titre,
    required String auteur,
    required String imageUrl,
  }) async {
    _setLoading(true);
    try {
      final reservation = await _service.reserver(
        userId: userId,
        catalogueId: catalogueId,
        titre: titre,
        auteur: auteur,
        imageUrl: imageUrl,
      );
      await chargerMesReservations(userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> annulerReservation(String reservationId, String catalogueId) async {
    _setLoading(true);
    try {
      await _service.annulerReservation(reservationId, catalogueId);
      await chargerMesReservations(
        _mesReservations.isNotEmpty ? _mesReservations.first.userId : ''
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // ========== UTILITAIRES ==========
  
  Future<int> getNombreReservations(String catalogueId) async {
    return await _service.getNombreReservations(catalogueId);
  }
  
  Future<bool> aDejaReserve(String userId, String catalogueId) async {
    return await _service.aDejaReserve(userId, catalogueId);
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
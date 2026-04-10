// message_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageController extends ChangeNotifier {
  final MessageService _service = MessageService();
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Charger tous les messages
  Future<void> chargerMessages() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _service.getAllMessages().listen((messages) {
        _messages = messages;
        _error = null;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Envoyer un message
  Future<bool> envoyerMessage(String contenu) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    if (contenu.trim().isEmpty) return false;
    
    // Récupérer le rôle de l'utilisateur
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final role = userDoc.data()?['role'] ?? 'usager';
    final nom = user.displayName ?? user.email?.split('@').first ?? 'Utilisateur';
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _service.envoyerMessage(
        contenu: contenu.trim(),
        expediteurId: user.uid,
        expediteurNom: nom,
        expediteurRole: role,
      );
      
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
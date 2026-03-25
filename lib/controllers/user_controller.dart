import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserController extends ChangeNotifier {
  final UserService _service = UserService();
  
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  
  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.role == 'admin';
  
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await _service.getCurrentUser();
    _isLoading = false;
    notifyListeners();
  }
  
  // 👈 Version corrigée avec plus de logs
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      print('🔍 Chargement des utilisateurs...');
      _users = await _service.getAllUsers();
      print('✅ ${_users.length} utilisateurs chargés');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur loadAllUsers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 👈 Charger uniquement les usagers
  Future<void> loadUsagers() async {
    _isLoading = true;
    notifyListeners();
    try {
      print('🔍 Chargement des usagers...');
      _users = await _service.getUsagers();
      print('✅ ${_users.length} usagers chargés');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur loadUsagers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> addUser({
    required String email,
    required String nom,
    required String prenom,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('➕ Création utilisateur: $email');
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        role: 'user',
        createdAt: DateTime.now(),
      );
      
      await _service.createUser(newUser);
      await loadAllUsers();
      print('✅ Utilisateur créé avec succès');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur addUser: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateUser(user);
      await loadAllUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteUser(uid);
      await loadAllUsers();
      return true;
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
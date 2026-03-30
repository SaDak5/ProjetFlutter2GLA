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
  int get limiteEmprunts => _currentUser?.limiteEmprunts ?? 5;
  int get nbEmpruntsActifs => _currentUser?.nbEmpruntsActifs ?? 0;
  
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await _service.getCurrentUser();
    _isLoading = false;
    notifyListeners();
  }
  
  // 👈 UTILISER getAllUsers
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _service.getAllUsers();  // ✅ Maintenant disponible
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadUsagers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _service.getUsagers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<int> countUsers() async {
    try {
      return await _service.countUsers();
    } catch (e) {
      return 0;
    }
  }
  
  Future<void> initialiserUtilisateur() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;
    if (userId == null || email == null) return;
    
    await _service.creerUtilisateurSiExistePas(
      uid: userId,
      email: email,
      role: 'usager',
      limiteEmprunts: 5,
    );
    await loadCurrentUser();
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
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final newUser = UserModel(
      uid: userCredential.user!.uid,
      nom: nom,
      prenom: prenom,
      email: email,
      role: 'usager',
      createdAt: DateTime.now(),
      limiteEmprunts: 5,     
      nbEmpruntsActifs: 0,  
    );
    
    await _service.createUser(newUser);
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
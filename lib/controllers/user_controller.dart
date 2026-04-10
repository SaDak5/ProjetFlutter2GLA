import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 IMPORTANT: Ajouter cet import
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserController extends ChangeNotifier {
  final UserService _service = UserService();
  
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  
  // 👈 AJOUTER CETTE PROPRIÉTÉ POUR LE LISTENER
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  
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
    
    // 👈 DÉMARRER L'ÉCOUTE EN TEMPS RÉEL APRÈS LE CHARGEMENT
    _listenToUserChanges();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 👈 NOUVELLE MÉTHODE : Écouter les changements Firestore
  void _listenToUserChanges() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Annuler l'ancienne subscription si elle existe
    _userSubscription?.cancel();
    
    // Écouter les changements en temps réel
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final updatedUser = UserModel.fromFirestore(
              snapshot.id, 
              snapshot.data() as Map<String, dynamic>
            );
            
            // Mettre à jour le currentUser
            _currentUser = updatedUser;
            
            // 👈 NOTIFIER L'UI DU CHANGEMENT
            notifyListeners();
            
            print('✅ UserController: nbEmpruntsActifs mis à jour = ${updatedUser.nbEmpruntsActifs}');
          }
        }, onError: (error) {
          print('❌ Erreur écoute utilisateur: $error');
        });
  }
  
  // 👈 MÉTHODE POUR NETTOYER LE LISTENER
  void disposeUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }
  
  @override
  void dispose() {
    disposeUserListener();
    super.dispose();
  }
  
  // 👈 AJOUTER UNE MÉTHODE POUR RAFRAÎCHIR MANUELLEMENT (FALLBACK)
  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      final updated = await _service.getUserById(_currentUser!.uid);
      if (updated != null) {
        _currentUser = updated;
        notifyListeners();
      }
    }
  }
  
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _service.getAllUsers();
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
    await loadCurrentUser(); // Cette méthode démarre le listener
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
      
      // Si l'utilisateur mis à jour est l'utilisateur courant
      if (_currentUser?.uid == user.uid) {
        _currentUser = user;
        notifyListeners();
      }
      
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
      
      // Si l'utilisateur supprimé est l'utilisateur courant
      if (_currentUser?.uid == uid) {
        disposeUserListener(); // Nettoyer le listener
        await FirebaseAuth.instance.signOut();
        _currentUser = null;
      }
      
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // 👈 Récupérer TOUS les utilisateurs (sans filtre pour tester)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      print('📊 Nombre total d\'utilisateurs: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('👤 Utilisateur: ${data['email']} - Role: ${data['role']}');
        return UserModel.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }
  
  // 👈 Récupérer uniquement les usagers (role = 'user')
  Future<List<UserModel>> getUsagers() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('role', isEqualTo: 'user')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('📊 Nombre d\'usagers: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) => 
          UserModel.fromFirestore(doc.id, doc.data())
      ).toList();
    } catch (e) {
      print('❌ Erreur getUsagers: $e');
      return [];
    }
  }

  // Récupérer l'utilisateur connecté
  Future<UserModel?> getCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    final doc = await _firestore.collection(_collectionName).doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  // Vérifier si l'utilisateur est admin
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.role == 'admin';
  }
  
  // Créer un utilisateur
  Future<void> createUser(UserModel user) async {
    await _firestore.collection(_collectionName).doc(user.uid).set(user.toFirestore());
  }
  
  // Créer un utilisateur si n'existe pas
  Future<void> creerUtilisateurSiExistePas({
    required String uid,
    required String email,
    String role = 'user',
  }) async {
    final doc = await _firestore.collection(_collectionName).doc(uid).get();
    if (!doc.exists) {
      final newUser = UserModel(
        uid: uid,
        nom: '',
        prenom: '',
        email: email,
        role: role,
      );
      await _firestore.collection(_collectionName).doc(uid).set(newUser.toFirestore());
    }
  }
  
  // Mettre à jour un utilisateur
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection(_collectionName).doc(user.uid).update(user.toFirestore());
  }
  
  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    await _firestore.collection(_collectionName).doc(uid).delete();
  }
  
  // Compter le nombre d'utilisateurs
  Future<int> countUsers() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('role', isEqualTo: 'user')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
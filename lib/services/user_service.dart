import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // 👈 AJOUTER CETTE MÉTHODE
  // Récupérer TOUS les utilisateurs (sans filtre)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      print('📊 Nombre total d\'utilisateurs: ${snapshot.docs.length}');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  // Récupérer tous les utilisateurs (usagers seulement)
  Future<List<UserModel>> getUsagers() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('role', isEqualTo: 'usager')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => 
          UserModel.fromFirestore(doc.id, doc.data())
      ).toList();
    } catch (e) {
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
  // Créer un utilisateur si n'existe pas
Future<void> creerUtilisateurSiExistePas({
  required String uid,
  required String email,
  String nom = '',
  String prenom = '',
  String role = 'usager',
  int limiteEmprunts = 5,
}) async {
  final doc = await _firestore.collection(_collectionName).doc(uid).get();
  if (!doc.exists) {
    await _firestore.collection(_collectionName).doc(uid).set({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'limiteEmprunts': limiteEmprunts,
      'nbEmpruntsActifs': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
        .where('role', isEqualTo: 'usager')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
  
  // Mettre à jour les emprunts actifs
  Future<void> incrementerEmpruntsActifs(String userId, int nombre) async {
    await _firestore.collection(_collectionName).doc(userId).update({
      'nbEmpruntsActifs': FieldValue.increment(nombre),
    });
  }
  
  Future<void> decrementerEmpruntsActifs(String userId, int nombre) async {
    await _firestore.collection(_collectionName).doc(userId).update({
      'nbEmpruntsActifs': FieldValue.increment(-nombre),
    });
  }
}


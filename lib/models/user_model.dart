import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.createdAt,
  });

  // Convertir UserModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Créer UserModel à partir d'un document Firestore
  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      uid: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'usager',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Pour afficher dans les logs
  @override
  String toString() {
    return 'UserModel(uid: $uid, nom: $nom, prenom: $prenom, email: $email, role: $role)';
  }

   bool get isAdmin => role == 'admin';
}
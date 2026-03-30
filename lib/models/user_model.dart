import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final DateTime? createdAt;
  final int limiteEmprunts;
  final int nbEmpruntsActifs;

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.createdAt,
    this.limiteEmprunts = 5,
    this.nbEmpruntsActifs = 0,
  });

  // Convertir UserModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'limiteEmprunts': limiteEmprunts,
      'nbEmpruntsActifs': nbEmpruntsActifs,
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
      limiteEmprunts: (data['limiteEmprunts'] ?? 5).toInt(),
      nbEmpruntsActifs: (data['nbEmpruntsActifs'] ?? 0).toInt(),
    );
  }

  // Pour afficher dans les logs
  @override
  String toString() {
    return 'UserModel(uid: $uid, nom: $nom, prenom: $prenom, email: $email, role: $role, limite: $limiteEmprunts, emprunts: $nbEmpruntsActifs)';
  }

  bool get isAdmin => role == 'admin';
}
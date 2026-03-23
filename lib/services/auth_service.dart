import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ AJOUTEZ CE CONSTRUCTEUR
  AuthService() {
    // Désactive la vérification reCAPTCHA pour le développement
    _auth.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  // SIGN UP
  Future<UserModel?> signUp({
    required String nom,
    required String prenom,
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Tentative d\'inscription pour: $email');
      
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;
      print('✅ Utilisateur créé avec UID: $uid');

      UserModel user = UserModel(
        uid: uid,
        nom: nom,
        prenom: prenom,
        email: email,
        role: "usager",
      );

      await _firestore.collection("users").doc(uid).set(user.toFirestore());
      print('✅ Données utilisateur sauvegardées dans Firestore');

      return user;
    } catch (e) {
      print('❌ Erreur signUp: $e');
      return null;
    }
  }

  // LOGIN
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Tentative de connexion pour: $email');
      
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Connexion réussie pour: ${cred.user!.uid}');

      final doc =
          await _firestore.collection("users").doc(cred.user!.uid).get();

      return UserModel.fromFirestore(
        cred.user!.uid,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      print('❌ Erreur signIn: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    print('🔓 Déconnexion réussie');
  }
}
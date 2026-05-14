import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ouvrir le sélecteur de compte Google
  Future<GoogleSignInAccount?> selectGoogleAccount() async {
    try {
      await _googleSignIn.signOut();
      return await _googleSignIn.signIn();
    } catch (e) {
      print('❌ Erreur sélection compte Google: $e');
      return null;
    }
  }

  // Se connecter à Firebase avec un compte Google déjà sélectionné
  Future<User?> signInWithGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

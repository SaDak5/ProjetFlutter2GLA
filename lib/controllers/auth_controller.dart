import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<UserModel?> signUp({
    required String nom,
    required String prenom,
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signUp(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
      );
    } catch (e) {
      print('Erreur signUp: $e');
      return null;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Erreur signIn: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
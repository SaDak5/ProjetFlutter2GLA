import '../models/user_model.dart';
import '../services/user_service.dart';

class UserController {
  final UserService _userService = UserService();

  // =============== TEST DE CONNEXION ===============

  Future<bool> testFirestoreConnection() async {
    print('🔄 Test de connexion via Controller...');

    try {
      bool result = await _userService.testFirestoreConnection();

      if (result) {
        print('✅ Connexion Firestore OK');
      } else {
        print('❌ Connexion Firestore échouée');
      }

      return result;
    } catch (e) {
      print('❌ Erreur Controller: $e');
      return false;
    }
  }

  // =============== RÉCUPÉRATION DES UTILISATEURS ===============

  Future<List<UserModel>> getAllUsers() async {
    try {
      print('🔄 Controller: récupération des utilisateurs...');

      List<UserModel> users = await _userService.getAllUsers();

      print('📊 Nombre d\'utilisateurs: ${users.length}');

      return users;
    } catch (e) {
      print('❌ Erreur Controller getAllUsers: $e');
      return [];
    }
  }
}
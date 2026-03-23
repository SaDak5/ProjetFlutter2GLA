import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TEST connexion
  Future<bool> testFirestoreConnection() async {
    try {
      await _firestore.collection('_connection_test').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('_connection_test').doc('test').delete();

      return true;
    } catch (e) {
      print('Erreur Service: $e');
      return false;
    }
  }

  // récupérer utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();

    return snapshot.docs.map((doc) {
      return UserModel.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
  }
}
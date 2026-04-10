// message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'messages';

  // Envoyer un message
  Future<bool> envoyerMessage({
    required String contenu,
    required String expediteurId,
    required String expediteurNom,
    required String expediteurRole,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        contenu: contenu,
        expediteurId: expediteurId,
        expediteurNom: expediteurNom,
        expediteurRole: expediteurRole,
        dateEnvoi: DateTime.now(),
      );

      await _firestore.collection(_collection).add(message.toFirestore());
      return true;
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      return false;
    }
  }

  // Récupérer tous les messages (ordre chronologique)
  Stream<List<MessageModel>> getAllMessages() {
    return _firestore
        .collection(_collection)
        .orderBy('dateEnvoi', descending: false) // Du plus ancien au plus récent
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
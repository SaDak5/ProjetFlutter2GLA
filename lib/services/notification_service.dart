import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Créer une notification dans la collection
  Future<void> createNotification(Map<String, dynamic> data) async {
    await _db.collection('notifications').add(data);
  }

  // Récupérer les notifications pour l'admin
  Stream<QuerySnapshot> getAdminNotifications() {
    return _db.collection('notifications')
        .where('targetRole', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Marquer comme lu
  Future<void> markAsRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({'isRead': true});
  }

  // Supprimer une notification ancienne
  Future<void> deleteNotification(String docId) async {
    await _db.collection('notifications').doc(docId).delete();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String eventId;
  final String title;
  final String message;
  final DateTime eventDate;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.message,
    required this.eventDate,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }
}
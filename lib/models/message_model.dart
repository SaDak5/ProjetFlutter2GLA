// message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String contenu;
  final String expediteurId;
  final String expediteurNom;
  final String expediteurRole; // 'admin' ou 'usager'
  final DateTime dateEnvoi;

  MessageModel({
    required this.id,
    required this.contenu,
    required this.expediteurId,
    required this.expediteurNom,
    required this.expediteurRole,
    required this.dateEnvoi,
  });

  factory MessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      contenu: data['contenu'] ?? '',
      expediteurId: data['expediteurId'] ?? '',
      expediteurNom: data['expediteurNom'] ?? '',
      expediteurRole: data['expediteurRole'] ?? 'usager',
      dateEnvoi: (data['dateEnvoi'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contenu': contenu,
      'expediteurId': expediteurId,
      'expediteurNom': expediteurNom,
      'expediteurRole': expediteurRole,
      'dateEnvoi': Timestamp.fromDate(dateEnvoi),
    };
  }
}
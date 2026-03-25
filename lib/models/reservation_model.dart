import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String userId;
  final String catalogueId;
  final String titre;
  final String auteur;
  final String imageUrl;
  final DateTime dateReservation;
  final StatusReservation statut;
  final int positionFile;
  
  ReservationModel({
    required this.id,
    required this.userId,
    required this.catalogueId,
    required this.titre,
    required this.auteur,
    required this.imageUrl,
    required this.dateReservation,
    this.statut = StatusReservation.enAttente,
    this.positionFile = 0,
  });
  
  factory ReservationModel.fromMap(Map<String, dynamic> data, String id) {
    return ReservationModel(
      id: id,
      userId: data['userId'] ?? '',
      catalogueId: data['catalogueId'] ?? '',
      titre: data['titre'] ?? '',
      auteur: data['auteur'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      dateReservation: (data['dateReservation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: StatusReservation.values.firstWhere(
        (e) => e.toString() == data['statut'],
        orElse: () => StatusReservation.enAttente,
      ),
      positionFile: data['positionFile'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'catalogueId': catalogueId,
      'titre': titre,
      'auteur': auteur,
      'imageUrl': imageUrl,
      'dateReservation': Timestamp.fromDate(dateReservation),
      'statut': statut.toString(),
      'positionFile': positionFile,
    };
  }
}

enum StatusReservation { enAttente, disponible, expiree, annulee }

extension StatusReservationExtension on StatusReservation {
  String get libelle {
    switch (this) {
      case StatusReservation.enAttente: return 'En attente';
      case StatusReservation.disponible: return 'Disponible';
      case StatusReservation.expiree: return 'Expirée';
      case StatusReservation.annulee: return 'Annulée';
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class EmpruntModel {
  final String id;
  final String userId;
  final String catalogueId;
  final String titre;
  final String auteur;
  final String imageBase64;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevu;
  final DateTime? dateRetourEffective; // Optionnel : pour savoir quand il a été rendu
  final int nbExemplaires;
  final String statut; // 'actif' ou 'retourne'

  EmpruntModel({
    required this.id,
    required this.userId,
    required this.catalogueId,
    required this.titre,
    required this.auteur,
    required this.imageBase64,
    required this.dateEmprunt,
    required this.dateRetourPrevu,
    this.dateRetourEffective,
    this.nbExemplaires = 1,
    this.statut = 'actif', // Par défaut à la création
  });

  factory EmpruntModel.fromMap(Map<String, dynamic> data, String id) {
    return EmpruntModel(
      id: id,
      userId: data['userId'] ?? '',
      catalogueId: data['catalogueId'] ?? '',
      titre: data['titre'] ?? '',
      auteur: data['auteur'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      dateEmprunt: (data['dateEmprunt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateRetourPrevu: (data['dateRetourPrevu'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateRetourEffective: (data['dateRetourEffective'] as Timestamp?)?.toDate(),
      nbExemplaires: (data['nbExemplaires'] ?? 1).toInt(),
      statut: data['statut'] ?? 'actif',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'catalogueId': catalogueId,
      'titre': titre,
      'auteur': auteur,
      'imageBase64': imageBase64,
      'dateEmprunt': Timestamp.fromDate(dateEmprunt),
      'dateRetourPrevu': Timestamp.fromDate(dateRetourPrevu),
      'dateRetourEffective': dateRetourEffective != null ? Timestamp.fromDate(dateRetourEffective!) : null,
      'nbExemplaires': nbExemplaires,
      'statut': statut,
    };
  }
}
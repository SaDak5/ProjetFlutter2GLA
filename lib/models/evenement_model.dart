import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvenementModel {
  final String id;
  final String titre;
  final String description;
  final String imageBase64;
  final DateTime date;
  final String lieu;
  final String adresse;
  final int nombrePlaces;
  final int placesReservees;
  final double prix;
  final String type;
  final bool estGratuit;
  final bool estAnnule;
  final DateTime dateCreation;
  final Map<String, int> reservations; // 👈 userId -> nombre de places réservées
  
  File? localImage;
  
  EvenementModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.imageBase64,
    required this.date,
    required this.lieu,
    required this.adresse,
    required this.nombrePlaces,
    this.placesReservees = 0,
    required this.prix,
    required this.type,
    this.estGratuit = false,
    this.estAnnule = false,
    required this.dateCreation,
    this.reservations = const {},
    this.localImage,
  });
  
  factory EvenementModel.fromMap(Map<String, dynamic> data, String id) {
    // Récupérer les réservations
    Map<String, int> reservationsMap = {};
    final reservationsData = data['reservations'];
    if (reservationsData != null && reservationsData is Map) {
      reservationsData.forEach((key, value) {
        reservationsMap[key.toString()] = (value as num).toInt();
      });
    }
    
    return EvenementModel(
      id: id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lieu: data['lieu'] ?? '',
      adresse: data['adresse'] ?? '',
      nombrePlaces: (data['nombrePlaces'] ?? 0).toInt(),
      placesReservees: (data['placesReservees'] ?? 0).toInt(),
      prix: (data['prix'] ?? 0).toDouble(),
      type: data['type'] ?? 'atelier',
      estGratuit: data['estGratuit'] ?? false,
      estAnnule: data['estAnnule'] ?? false,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reservations: reservationsMap,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'imageBase64': imageBase64,
      'date': Timestamp.fromDate(date),
      'lieu': lieu,
      'adresse': adresse,
      'nombrePlaces': nombrePlaces,
      'placesReservees': placesReservees,
      'prix': prix,
      'type': type,
      'estGratuit': estGratuit,
      'estAnnule': estAnnule,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'reservations': reservations,
    };
  }
  
  EvenementModel copyWith({
    String? id,
    String? titre,
    String? description,
    String? imageBase64,
    DateTime? date,
    String? lieu,
    String? adresse,
    int? nombrePlaces,
    int? placesReservees,
    double? prix,
    String? type,
    bool? estGratuit,
    bool? estAnnule,
    DateTime? dateCreation,
    Map<String, int>? reservations,
    File? localImage,
  }) {
    return EvenementModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      imageBase64: imageBase64 ?? this.imageBase64,
      date: date ?? this.date,
      lieu: lieu ?? this.lieu,
      adresse: adresse ?? this.adresse,
      nombrePlaces: nombrePlaces ?? this.nombrePlaces,
      placesReservees: placesReservees ?? this.placesReservees,
      prix: prix ?? this.prix,
      type: type ?? this.type,
      estGratuit: estGratuit ?? this.estGratuit,
      estAnnule: estAnnule ?? this.estAnnule,
      dateCreation: dateCreation ?? this.dateCreation,
      reservations: reservations ?? this.reservations,
      localImage: localImage ?? this.localImage,
    );
  }
  
  int get placesDisponibles => nombrePlaces - placesReservees;
  bool get estComplet => placesDisponibles <= 0;
  bool get estPasse => date.isBefore(DateTime.now());
  
  // Vérifier si un utilisateur a réservé
  bool aReserve(String userId) {
    return reservations.containsKey(userId);
  }
  
  // Obtenir le nombre de places réservées par un utilisateur
  int getPlacesReserveesByUser(String userId) {
    return reservations[userId] ?? 0;
  }
  
  // Obtenir la liste des IDs des participants
  List<String> get participantsIds {
    return reservations.keys.toList();
  }
  
  String get statut {
    if (estAnnule) return 'Annulé';
    if (estComplet) return 'Complet';
    if (estPasse) return 'Passé';
    return 'Disponible';
  }
}
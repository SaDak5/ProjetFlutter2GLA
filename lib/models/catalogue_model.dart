import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogueModel {
  final String id;
  final String nom;
  final String description;
  final String auteur;
  final double prix;
  final String imageBase64;
  final DateTime dateCreation;
  final bool estDisponible;
  final String categorie;
  final int nbExemplaires;           // Nombre total d'exemplaires
  final int nbExemplairesDisponibles; // Nombre d'exemplaires disponibles
  
  CatalogueModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.auteur,
    required this.prix,
    required this.imageBase64,
    required this.dateCreation,
    this.estDisponible = true,
    required this.categorie,
    required this.nbExemplaires,
    required this.nbExemplairesDisponibles,
  });
  
  factory CatalogueModel.fromMap(Map<String, dynamic> data, String id) {
    return CatalogueModel(
      id: id,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      auteur: data['auteur'] ?? '',
      prix: (data['prix'] ?? 0).toDouble(),
      imageBase64: data['imageBase64'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estDisponible: data['estDisponible'] ?? true,
      categorie: data['categorie'] ?? 'Non classé',
      nbExemplaires: (data['nbExemplaires'] ?? 1).toInt(),
      nbExemplairesDisponibles: (data['nbExemplairesDisponibles'] ?? 1).toInt(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'auteur': auteur,
      'prix': prix,
      'imageBase64': imageBase64,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'estDisponible': estDisponible,
      'categorie': categorie,
      'nbExemplaires': nbExemplaires,
      'nbExemplairesDisponibles': nbExemplairesDisponibles,
    };
  }
  
  CatalogueModel copyWith({
    String? id,
    String? nom,
    String? description,
    String? auteur,
    double? prix,
    String? imageBase64,
    DateTime? dateCreation,
    bool? estDisponible,
    String? categorie,
    int? nbExemplaires,
    int? nbExemplairesDisponibles,
  }) {
    return CatalogueModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      auteur: auteur ?? this.auteur,
      prix: prix ?? this.prix,
      imageBase64: imageBase64 ?? this.imageBase64,
      dateCreation: dateCreation ?? this.dateCreation,
      estDisponible: estDisponible ?? this.estDisponible,
      categorie: categorie ?? this.categorie,
      nbExemplaires: nbExemplaires ?? this.nbExemplaires,
      nbExemplairesDisponibles: nbExemplairesDisponibles ?? this.nbExemplairesDisponibles,
    );
  }
  
  bool get estDisponibleEmprunt => nbExemplairesDisponibles > 0;
  String get statutDisponibilite {
    if (nbExemplairesDisponibles <= 0) return 'Indisponible';
    if (nbExemplairesDisponibles == 1) return '1 exemplaire disponible';
    return '$nbExemplairesDisponibles exemplaires disponibles';
  }
}
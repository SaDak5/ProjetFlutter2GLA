import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmpruntModel {
  final String id;
  final String userId;
  final String catalogueId;
  final String titre;
  final String auteur;
  final String imageUrl;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevu;
  DateTime? dateRetourEffectif;
  final StatusEmprunt statut;
  final int prolongations;
  final String codeBarres;
  final bool rappelEnvoye;
  final double amende;
  
  EmpruntModel({
    required this.id,
    required this.userId,
    required this.catalogueId,
    required this.titre,
    required this.auteur,
    required this.imageUrl,
    required this.dateEmprunt,
    required this.dateRetourPrevu,
    this.dateRetourEffectif,
    this.statut = StatusEmprunt.enCours,
    this.prolongations = 0,
    required this.codeBarres,
    this.rappelEnvoye = false,
    this.amende = 0,
  });
  
  factory EmpruntModel.fromMap(Map<String, dynamic> data, String id) {
    return EmpruntModel(
      id: id,
      userId: data['userId'] ?? '',
      catalogueId: data['catalogueId'] ?? '',
      titre: data['titre'] ?? '',
      auteur: data['auteur'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      dateEmprunt: (data['dateEmprunt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateRetourPrevu: (data['dateRetourPrevu'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateRetourEffectif: (data['dateRetourEffectif'] as Timestamp?)?.toDate(),
      statut: StatusEmprunt.values.firstWhere(
        (e) => e.toString() == data['statut'],
        orElse: () => StatusEmprunt.enCours,
      ),
      prolongations: data['prolongations'] ?? 0,
      codeBarres: data['codeBarres'] ?? '',
      rappelEnvoye: data['rappelEnvoye'] ?? false,
      amende: (data['amende'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'catalogueId': catalogueId,
      'titre': titre,
      'auteur': auteur,
      'imageUrl': imageUrl,
      'dateEmprunt': Timestamp.fromDate(dateEmprunt),
      'dateRetourPrevu': Timestamp.fromDate(dateRetourPrevu),
      'dateRetourEffectif': dateRetourEffectif != null ? Timestamp.fromDate(dateRetourEffectif!) : null,
      'statut': statut.toString(),
      'prolongations': prolongations,
      'codeBarres': codeBarres,
      'rappelEnvoye': rappelEnvoye,
      'amende': amende,
    };
  }
  
  bool get estEnRetard => DateTime.now().isAfter(dateRetourPrevu) && statut == StatusEmprunt.enCours;
  int get joursDeRetard => estEnRetard ? DateTime.now().difference(dateRetourPrevu).inDays : 0;
  double get calculerAmende => joursDeRetard * 1.0;
  bool get peutProlonger => statut == StatusEmprunt.enCours && prolongations < 2 && !estEnRetard;
}

enum StatusEmprunt { enCours, termine, enRetard, annule }

extension StatusEmpruntExtension on StatusEmprunt {
  String get libelle {
    switch (this) {
      case StatusEmprunt.enCours: return 'En cours';
      case StatusEmprunt.termine: return 'Terminé';
      case StatusEmprunt.enRetard: return 'En retard';
      case StatusEmprunt.annule: return 'Annulé';
    }
  }
  Color get couleur {
    switch (this) {
      case StatusEmprunt.enCours: return const Color(0xFF003366);
      case StatusEmprunt.termine: return const Color(0xFF006400);
      case StatusEmprunt.enRetard: return const Color(0xFF800020);
      case StatusEmprunt.annule: return Colors.grey;
    }
  }
}
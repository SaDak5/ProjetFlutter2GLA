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
  final DateTime? dateRetourEffective;
  final int nbExemplaires;
  final String statut;
  final String userNom;
  final String userPrenom;
  final String userEmail;

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
    this.statut = 'actif',
    this.userNom = '',
    this.userPrenom = '',
    this.userEmail = '',
  });

  factory EmpruntModel.fromMap(Map<String, dynamic> data, String id) {
    return EmpruntModel(
      id: id,
      userId:        _str(data['userId']),
      catalogueId:   _str(data['catalogueId']),
      titre:         _str(data['titre']),
      auteur:        _str(data['auteur']),
      imageBase64:   _str(data['imageBase64']),
      dateEmprunt:        _date(data['dateEmprunt'])        ?? DateTime.now(),
      dateRetourPrevu:    _date(data['dateRetourPrevu'])    ?? DateTime.now(),
      dateRetourEffective: _date(data['dateRetourEffective']),
      nbExemplaires: (data['nbExemplaires'] as num?)?.toInt() ?? 1,
      statut:        _str(data['statut'], fallback: 'actif'),
      userNom:       _str(data['userNom']),
      userPrenom:    _str(data['userPrenom']),
      userEmail:     _str(data['userEmail']),
    );
  }

  // ✅ Cast null-safe : n'importe quel type → String propre
  static String _str(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  // ✅ Cast null-safe pour Timestamp → DateTime
  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId':       userId,
      'catalogueId':  catalogueId,
      'titre':        titre,
      'auteur':       auteur,
      'imageBase64':  imageBase64,
      'dateEmprunt':        Timestamp.fromDate(dateEmprunt),
      'dateRetourPrevu':    Timestamp.fromDate(dateRetourPrevu),
      'dateRetourEffective': dateRetourEffective != null
          ? Timestamp.fromDate(dateRetourEffective!)
          : null,
      'nbExemplaires': nbExemplaires,
      'statut':        statut,
      'userNom':       userNom,
      'userPrenom':    userPrenom,
      'userEmail':     userEmail,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalogue_model.dart';

class CatalogueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _cataloguesCollection = 'catalogues';
  final String _empruntsCollection = 'emprunts';
  final String _usersCollection = 'users';

  Stream<List<CatalogueModel>> streamCatalogues() {
    return _firestore
        .collection(_cataloguesCollection)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CatalogueModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<CatalogueModel>> rechercherParNom(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore.collection(_cataloguesCollection).snapshots().map((snapshot) {
      final search = texte.toLowerCase();
      return snapshot.docs
          .where((doc) => (doc.data()['nom'] ?? '').toLowerCase().contains(search))
          .map((doc) => CatalogueModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<CatalogueModel>> rechercherParAuteur(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore.collection(_cataloguesCollection).snapshots().map((snapshot) {
      final search = texte.toLowerCase();
      return snapshot.docs
          .where((doc) => (doc.data()['auteur'] ?? '').toLowerCase().contains(search))
          .map((doc) => CatalogueModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<CatalogueModel>> rechercherParNomOuAuteur(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore.collection(_cataloguesCollection).snapshots().map((snapshot) {
      final search = texte.toLowerCase();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['nom'] ?? '').toLowerCase().contains(search) ||
            (data['auteur'] ?? '').toLowerCase().contains(search);
      }).map((doc) => CatalogueModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> ajouterCatalogue(CatalogueModel catalogue) async {
    await _firestore
        .collection(_cataloguesCollection)
        .doc(catalogue.id)
        .set(catalogue.toMap());
  }

  Future<void> modifierCatalogue(CatalogueModel catalogue) async {
    await _firestore
        .collection(_cataloguesCollection)
        .doc(catalogue.id)
        .update(catalogue.toMap());
  }

  Future<void> supprimerCatalogue(String id) async {
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(id);
    await _firestore.runTransaction((transaction) async {
      final empruntsQuery = await _firestore
          .collection(_empruntsCollection)
          .where('catalogueId', isEqualTo: id)
          .get();

      for (var empruntDoc in empruntsQuery.docs) {
        final empruntData = empruntDoc.data();
        final userId = empruntData['userId'] as String;
        final nbEmpruntes = (empruntData['nbExemplaires'] ?? 1).toInt();
        final userRef = _firestore.collection(_usersCollection).doc(userId);
        transaction.update(userRef, {
          'nbEmpruntsActifs': FieldValue.increment(-nbEmpruntes),
        });
        transaction.delete(empruntDoc.reference);
      }

      transaction.delete(catalogueRef);
    });
  }

  Future<void> decrementerExemplaires(String catalogueId, int nombreEmprunte) async {
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(catalogueRef);
      final data = doc.data() as Map<String, dynamic>;
      final nbDisponibles = (data['nbExemplairesDisponibles'] ?? 0).toInt();

      if (nbDisponibles < nombreEmprunte) {
        throw Exception('Plus assez d\'exemplaires disponibles');
      }

      transaction.update(catalogueRef, {
        'nbExemplairesDisponibles': nbDisponibles - nombreEmprunte,
      });
    });
  }

  Future<void> incrementerExemplaires(String catalogueId, int nombreRetourne) async {
    final catalogueRef = _firestore.collection(_cataloguesCollection).doc(catalogueId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(catalogueRef);
      final data = doc.data() as Map<String, dynamic>;
      final nbDisponibles = (data['nbExemplairesDisponibles'] ?? 0).toInt();

      transaction.update(catalogueRef, {
        'nbExemplairesDisponibles': nbDisponibles + nombreRetourne,
      });
    });
  }

  Future<int> getNbExemplairesDisponibles(String catalogueId) async {
    final doc = await _firestore.collection(_cataloguesCollection).doc(catalogueId).get();
    final data = doc.data() as Map<String, dynamic>;
    return (data['nbExemplairesDisponibles'] ?? 0).toInt();
  }
}
//
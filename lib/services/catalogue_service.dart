import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalogue_model.dart';

class CatalogueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<CatalogueModel>> streamCatalogues() {
    return _firestore
        .collection('catalogues')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            CatalogueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  Stream<List<CatalogueModel>> rechercherParNom(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore
        .collection('catalogues')
        .snapshots()
        .map((snapshot) {
          final results = <CatalogueModel>[];
          final search = texte.toLowerCase();
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['nom'] ?? '').toLowerCase().contains(search)) {
              results.add(CatalogueModel.fromMap(data, doc.id));
            }
          }
          return results;
        });
  }
  
  Stream<List<CatalogueModel>> rechercherParAuteur(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore
        .collection('catalogues')
        .snapshots()
        .map((snapshot) {
          final results = <CatalogueModel>[];
          final search = texte.toLowerCase();
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['auteur'] ?? '').toLowerCase().contains(search)) {
              results.add(CatalogueModel.fromMap(data, doc.id));
            }
          }
          return results;
        });
  }
  
  Stream<List<CatalogueModel>> rechercherParPrix(double min, double max) {
    return _firestore
        .collection('catalogues')
        .where('prix', isGreaterThanOrEqualTo: min)
        .where('prix', isLessThanOrEqualTo: max)
        .orderBy('prix')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            CatalogueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }
  
  Stream<List<CatalogueModel>> rechercherParNomOuAuteur(String texte) {
    if (texte.isEmpty) return streamCatalogues();
    return _firestore
        .collection('catalogues')
        .snapshots()
        .map((snapshot) {
          final results = <CatalogueModel>[];
          final search = texte.toLowerCase();
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nom = (data['nom'] ?? '').toLowerCase();
            final auteur = (data['auteur'] ?? '').toLowerCase();
            if (nom.contains(search) || auteur.contains(search)) {
              results.add(CatalogueModel.fromMap(data, doc.id));
            }
          }
          return results;
        });
  }
  
  Future<void> ajouterCatalogue(CatalogueModel catalogue) async {
    await _firestore.collection('catalogues').doc(catalogue.id).set(catalogue.toMap());
  }
  
  Future<void> modifierCatalogue(CatalogueModel catalogue) async {
    await _firestore.collection('catalogues').doc(catalogue.id).update(catalogue.toMap());
  }
  
  Future<void> supprimerCatalogue(String id) async {
    await _firestore.collection('catalogues').doc(id).delete();
  }



  // Ajouter ces méthodes dans CatalogueService

Future<void> decrementerExemplaires(String catalogueId) async {
  final catalogueRef = _firestore.collection('catalogues').doc(catalogueId);
  
  await _firestore.runTransaction((transaction) async {
    final doc = await transaction.get(catalogueRef);
    final data = doc.data() as Map<String, dynamic>;
    
    final nbDisponibles = (data['nbExemplairesDisponibles'] ?? 0).toInt();
    
    if (nbDisponibles <= 0) {
      throw Exception('Plus d\'exemplaires disponibles');
    }
    
    transaction.update(catalogueRef, {
      'nbExemplairesDisponibles': nbDisponibles - 1,
    });
  });
}

Future<void> incrementerExemplaires(String catalogueId) async {
  final catalogueRef = _firestore.collection('catalogues').doc(catalogueId);
  
  await _firestore.runTransaction((transaction) async {
    final doc = await transaction.get(catalogueRef);
    final data = doc.data() as Map<String, dynamic>;
    
    final nbDisponibles = (data['nbExemplairesDisponibles'] ?? 0).toInt();
    final nbTotal = (data['nbExemplaires'] ?? 0).toInt();
    
    if (nbDisponibles >= nbTotal) {
      throw Exception('Déjà tous les exemplaires disponibles');
    }
    
    transaction.update(catalogueRef, {
      'nbExemplairesDisponibles': nbDisponibles + 1,
    });
  });
}

Future<int> getNbExemplairesDisponibles(String catalogueId) async {
  final doc = await _firestore.collection('catalogues').doc(catalogueId).get();
  final data = doc.data() as Map<String, dynamic>;
  return (data['nbExemplairesDisponibles'] ?? 0).toInt();
}
}
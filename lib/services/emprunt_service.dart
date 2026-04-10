import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emprunt_model.dart';

class EmpruntService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _empruntsCollection = 'emprunts';
  final String _cataloguesCollection = 'catalogues';
  final String _usersCollection = 'users';

  // =========================
  // 🔹 EMPRUNTS UTILISATEUR
  // =========================
  Stream<List<EmpruntModel>> streamMesEmprunts(String userId) {
    return _firestore
        .collection(_empruntsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmpruntModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // =========================
  // 🔹 TOUS LES EMPRUNTS
  // =========================
  Stream<List<EmpruntModel>> streamTousLesEmprunts() {
    return _firestore
        .collection(_empruntsCollection)
        .orderBy('dateEmprunt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmpruntModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // =========================
  // 🔹 EMPRUNTER
  // =========================
  Future<void> emprunterAvecDate(
    String userId,
    String catalogueId,
    int nbExemplaires,
    DateTime dateRetour,
  ) async {
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    final catalogueRef =
        _firestore.collection(_cataloguesCollection).doc(catalogueId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final catalogueDoc = await transaction.get(catalogueRef);

      if (!userDoc.exists) throw Exception('Utilisateur introuvable');
      if (!catalogueDoc.exists) throw Exception('Catalogue introuvable');

      final userData = userDoc.data()!;
      final catalogueData = catalogueDoc.data()!;

      final nbActifs = (userData['nbEmpruntsActifs'] ?? 0).toInt();
      final limite = (userData['limiteEmprunts'] ?? 5).toInt();
      final dispo = (catalogueData['nbExemplairesDisponibles'] ?? 0).toInt();

      if (nbActifs + nbExemplaires > limite) {
        throw Exception('Limite atteinte');
      }

      if (dispo < nbExemplaires) {
        throw Exception('Stock insuffisant');
      }

      final empruntRef = _firestore.collection(_empruntsCollection).doc();

      final emprunt = EmpruntModel(
        id: empruntRef.id,
        userId: userId,
        catalogueId: catalogueId,
        titre: catalogueData['nom'] ?? '',
        auteur: catalogueData['auteur'] ?? '',
        imageBase64: catalogueData['imageBase64'] ?? '',
        dateEmprunt: DateTime.now(),
        dateRetourPrevu: dateRetour,
        nbExemplaires: nbExemplaires,
        // ✅ Snapshot des infos user au moment de l'emprunt
        userNom: userData['nom'] ?? '',
        userPrenom: userData['prenom'] ?? '',
        userEmail: userData['email'] ?? '',
      );

      transaction.set(empruntRef, {
        ...emprunt.toMap(),
        'statut': 'en cours',
      });

      transaction.update(catalogueRef, {
        'nbExemplairesDisponibles': dispo - nbExemplaires,
      });

      transaction.update(userRef, {
        'nbEmpruntsActifs': nbActifs + nbExemplaires,
      });
    });
  }

  // =========================
  // 🔹 RETOUR
  // =========================
  Future<void> retourner(
    String empruntId,
    String catalogueId,
    int nbExemplairesARendre,
  ) async {
    final empruntRef =
        _firestore.collection(_empruntsCollection).doc(empruntId);
    final catalogueRef =
        _firestore.collection(_cataloguesCollection).doc(catalogueId);

    await _firestore.runTransaction((transaction) async {
      final empruntDoc = await transaction.get(empruntRef);
      final catalogueDoc = await transaction.get(catalogueRef);

      if (!empruntDoc.exists) throw Exception('Emprunt introuvable');
      if (!catalogueDoc.exists) throw Exception('Catalogue introuvable');

      final empruntData = empruntDoc.data()!;
      final userId = empruntData['userId'];

      final int nbPossedes = (empruntData['nbExemplaires'] ?? 0).toInt();
      if (nbPossedes <= 0) {
        throw Exception('Cet emprunt est déjà totalement retourné');
      }

      final int nbEffectifARendre =
          nbExemplairesARendre > nbPossedes ? nbPossedes : nbExemplairesARendre;
      final int resteAPosseder = nbPossedes - nbEffectifARendre;

      transaction.update(empruntRef, {
        'nbExemplaires': resteAPosseder,
        'statut': resteAPosseder == 0 ? 'retourné' : 'partiel',
        'dateRetourEffective':
            resteAPosseder == 0 ? FieldValue.serverTimestamp() : null,
      });

      transaction.update(catalogueRef, {
        'nbExemplairesDisponibles': FieldValue.increment(nbEffectifARendre),
      });

      transaction.update(
        _firestore.collection(_usersCollection).doc(userId),
        {'nbEmpruntsActifs': FieldValue.increment(-nbEffectifARendre)},
      );
    });
  }
}
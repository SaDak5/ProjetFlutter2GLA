import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EvenementImminent {
  final String id;
  final String titre;
  final DateTime date;
  final String type;
  final String lieu;
  
  EvenementImminent({
    required this.id,
    required this.titre,
    required this.date,
    required this.type,
    required this.lieu,
  });
  
  String get tempsRestant {
    final difference = date.difference(DateTime.now());
    if (difference.inDays > 0) {
      return 'Dans ${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return 'Dans ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Dans ${difference.inMinutes}min';
    } else {
      return 'Commence maintenant !';
    }
  }
  
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}

class NotificationController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<EvenementImminent> _evenementsImminents = [];
  List<Map<String, dynamic>> _notificationsNonLues = [];
  int _unreadCount = 0;
  
  // Stream pour les notifications non lues (unique)
  Stream<QuerySnapshot>? _notificationsStream;
  
  List<EvenementImminent> get evenementsImminents => _evenementsImminents;
  List<Map<String, dynamic>> get notificationsNonLues => _notificationsNonLues;
  int get unreadCount => _unreadCount;
  
  // ========== INITIALISATION ==========
  
  void init() {
    // Initialiser le stream des notifications
    _notificationsStream = _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    // Écouter les changements
    _notificationsStream?.listen((snapshot) {
      final List<Map<String, dynamic>> allNotifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Filtrer les non lues pour ADMIN uniquement (notifications avec targetRole='admin')
      _notificationsNonLues = allNotifications
          .where((notif) => notif['isRead'] == false && notif['targetRole'] == 'admin')
          .toList();
      
      // Mettre à jour le compteur admin
      _unreadCount = _notificationsNonLues.length;
      
      notifyListeners();
      
      if (_unreadCount > 0) {
        print('🔔 ADMIN: $_unreadCount notification(s) non lue(s)');
      }
    });
  }
  
  // ========== STREAM EN TEMPS RÉEL DES ÉVÉNEMENTS IMMINENTS ==========
  
  Stream<List<EvenementImminent>> streamEvenementsImminents() {
    final maintenant = DateTime.now();
    final dans24h = maintenant.add(const Duration(hours: 24));
    
    return _db
        .collection('evenements')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(maintenant))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dans24h))
        .where('estAnnule', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return EvenementImminent(
              id: doc.id,
              titre: data['titre'] ?? 'Événement sans titre',
              date: (data['date'] as Timestamp).toDate(),
              type: data['type'] ?? 'Événement',
              lieu: data['lieu'] ?? 'Lieu non spécifié',
            );
          }).toList();
          
          _evenementsImminents = events;
          notifyListeners();
          
          return events;
        });
  }
  
  // ========== CRÉATION AUTOMATIQUE DES NOTIFICATIONS POUR ÉVÉNEMENTS (ADMIN SEULEMENT) ==========
  
  Stream<void> autoCreateNotifications() {
    final maintenant = DateTime.now();
    final dans24h = maintenant.add(const Duration(hours: 24));
    
    return _db
        .collection('evenements')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(maintenant))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dans24h))
        .where('estAnnule', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
          for (var doc in snapshot.docs) {
            final eventData = doc.data() as Map<String, dynamic>;
            final eventId = doc.id;
            final eventTitle = eventData['titre'] ?? 'Événement sans titre';
            final eventDate = (eventData['date'] as Timestamp).toDate();
            
            // Vérifier si une notification existe déjà
            final existingNotif = await _db
                .collection('notifications')
                .where('eventId', isEqualTo: eventId)
                .where('type', isEqualTo: 'upcoming_event')
                .limit(1)
                .get();
            
            if (existingNotif.docs.isEmpty) {
              // Créer la notification pour l'ADMIN SEULEMENT
              await _db.collection('notifications').add({
                'eventId': eventId,
                'title': '📅 Événement imminent !',
                'message': 'L\'événement "$eventTitle" commence dans moins de 24h',
                'eventDate': Timestamp.fromDate(eventDate),
                'eventTitle': eventTitle,
                'eventType': eventData['type'] ?? 'Événement',
                'eventLieu': eventData['lieu'] ?? 'Lieu non spécifié',
                'type': 'upcoming_event',
                'targetRole': 'admin',  // 👈 Pour l'admin
                'targetUserId': null,   // 👈 Pas d'utilisateur cible
                'isRead': false,
                'createdAt': Timestamp.now(),
              });
              print('✅ Notification ADMIN créée pour événement: $eventTitle');
            }
          }
        });
  }
  
  // ========== DÉTECTION DES EMPRUNTS EN RETARD POUR L'UTILISATEUR CONCERNÉ SEULEMENT ==========
  
  Stream<void> autoCreateRetardNotificationsForUsers() {
    final maintenant = DateTime.now();
    
    print('🔍 === SURVEILLANCE DES RETARDS POUR UTILISATEURS ===');
    
    return _db
        .collection('emprunts')
        .where('statut', isEqualTo: 'en cours')
        .snapshots()
        .asyncMap((snapshot) async {
          print('📊 Nombre d\'emprunts en cours: ${snapshot.docs.length}');
          
          for (var doc in snapshot.docs) {
            final empruntData = doc.data() as Map<String, dynamic>;
            final empruntId = doc.id;
            
            // Vérifier si dateRetourPrevu existe
            if (!empruntData.containsKey('dateRetourPrevu')) {
              continue;
            }
            
            final dateRetourPrevu = (empruntData['dateRetourPrevu'] as Timestamp).toDate();
            final userId = empruntData['userId'];
            final catalogueId = empruntData['catalogueId'];
            final nbExemplaires = empruntData['nbExemplaires'] ?? 1;
            final userPrenom = empruntData['userPrenom'] ?? '';
            final userNom = empruntData['userNom'] ?? '';
            
            // Vérifier si l'emprunt est en retard
            if (dateRetourPrevu.isBefore(maintenant)) {
              print('⚠️ RETARD DÉTECTÉ pour l\'utilisateur: $userId');
              
              // Récupérer les infos du catalogue
              final catalogueDoc = await _db.collection('catalogues').doc(catalogueId).get();
              final catalogueData = catalogueDoc.data() as Map<String, dynamic>?;
              final livreTitre = catalogueData?['nom'] ?? 'Livre inconnu';
              
              // Calculer le nombre de jours de retard
              final joursRetard = maintenant.difference(dateRetourPrevu).inDays;
              
              // Vérifier si une notification de retard existe déjà pour CET utilisateur
              final existingNotif = await _db
                  .collection('notifications')
                  .where('empruntId', isEqualTo: empruntId)
                  .where('userId', isEqualTo: userId)
                  .where('type', isEqualTo: 'retard_utilisateur')
                  .limit(1)
                  .get();
              
              if (existingNotif.docs.isEmpty) {
                // Créer la notification pour L'UTILISATEUR CONCERNÉ SEULEMENT
                await _db.collection('notifications').add({
                  'empruntId': empruntId,
                  'userId': userId,
                  'catalogueId': catalogueId,
                  'title': '⚠️ Retard de retour !',
                  'message': 'Votre emprunt "$livreTitre" est en retard de $joursRetard jour(s). Veuillez le retourner dès que possible.',
                  'livreTitre': livreTitre,
                  'userPrenom': userPrenom,
                  'userNom': userNom,
                  'dateRetourPrevu': Timestamp.fromDate(dateRetourPrevu),
                  'nbExemplaires': nbExemplaires,
                  'joursRetard': joursRetard,
                  'type': 'retard_utilisateur',
                  'targetRole': 'user',           // 👈 Pour l'utilisateur
                  'targetUserId': userId,         // 👈 L'utilisateur spécifique
                  'isRead': false,
                  'createdAt': Timestamp.now(),
                });
                print('✅ Notification créée pour l\'utilisateur $userId: $livreTitre ($joursRetard jours)');
              } else {
                print('ℹ️ Notification déjà existante pour l\'utilisateur $userId');
              }
            }
          }
          print('🔍 === FIN SURVEILLANCE RETARDS ===\n');
        });
  }
  
  // ========== STREAM DES NOTIFICATIONS NON LUES POUR UN UTILISATEUR SPÉCIFIQUE ==========
  // Uniquement pour les notifications où targetUserId correspond à l'utilisateur
  
  Stream<List<Map<String, dynamic>>> streamUserNotifications(String userId) {
    print('🔔 Stream notifications utilisateur pour: $userId');
    
    return _db
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          print('🔔 ${notifications.length} notification(s) non lue(s) pour l\'utilisateur $userId');
          return notifications;
        });
  }
  
  // ========== STREAM DU COMPTEUR POUR UN UTILISATEUR SPÉCIFIQUE ==========
  
  Stream<int> getUserUnreadCountStream(String userId) {
    return _db
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final count = snapshot.docs.length;
          print('🔔 Compteur utilisateur $userId: $count notification(s) de retard');
          return count;
        });
  }
  
  // ========== STREAM DES NOTIFICATIONS NON LUES POUR ADMIN ==========
  // Uniquement pour les notifications avec targetRole='admin'
  
  Stream<List<Map<String, dynamic>>> streamNotificationsNonLues() {
    return Stream.value(_notificationsNonLues).asBroadcastStream();
  }
  
  // ========== STREAM DU COMPTEUR POUR ADMIN ==========
  
  Stream<int> getUnreadCountStream() {
    return Stream.value(_unreadCount).asBroadcastStream();
  }
  
  // ========== MARQUER COMME LU ==========
  
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      print('✅ Notification $notificationId marquée comme lue');
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
  
  // Marquer toutes les notifications admin comme lues
  Future<void> marquerToutCommeLu() async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('targetRole', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();
      
      _unreadCount = 0;
      notifyListeners();
      print('✅ ${snapshot.docs.length} notifications admin marquées comme lues');
    } catch (e) {
      print('❌ Erreur lors du marquage des notifications admin: $e');
    }
  }
  
  // Marquer comme lu pour un utilisateur spécifique (ses notifications de retard)
  Future<void> marquerToutCommeLuPourUtilisateur(String userId) async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('targetUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();
      
      print('✅ ${snapshot.docs.length} notifications marquées comme lues pour l\'utilisateur $userId');
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
  
  // ========== NETTOYAGE (ADMIN UNIQUEMENT) ==========
  
  Future<void> nettoyerAnciennesNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final isAdmin = userDoc.data()?['role'] == 'admin';
      
      // Seul l'admin peut nettoyer les anciennes notifications
      if (!isAdmin) {
        print('ℹ️ Seul l\'admin peut nettoyer les anciennes notifications');
        return;
      }
      
      final ilYADixJours = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _db
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(ilYADixJours))
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ ${snapshot.docs.length} anciennes notifications supprimées');
      }
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
  
  // ========== NETTOYAGE DES RESSOURCES ==========
  
  @override
  void dispose() {
    _notificationsStream = null;
    super.dispose();
  }
}
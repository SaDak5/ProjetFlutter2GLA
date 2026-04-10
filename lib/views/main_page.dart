import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../controllers/emprunt_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/notification_controller.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late StreamSubscription _evenementsSubscription;
  late StreamSubscription _notificationsSubscription;
  late StreamSubscription _retardsUtilisateurSubscription;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = true;
  bool _showNotificationBanner = false;
  EvenementImminent? _dernierEvenement;

  @override
  void initState() {
    super.initState();

    // Animation pour le banner de notification
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _initRealTimeNotifications();
    });
  }

  void _initRealTimeNotifications() {
    final notificationController = Provider.of<NotificationController>(
      context,
      listen: false,
    );

    // Initialiser le controller
    notificationController.init();

    // 🔥 ÉCOUTER LES ÉVÉNEMENTS IMMINENTS
    _evenementsSubscription = notificationController
        .streamEvenementsImminents()
        .listen((events) {
          if (events.isNotEmpty && mounted) {
            final dernierEvent = events.first;
            _showRealTimeNotification(dernierEvent);
          }
        });

    // 🔥 CRÉER AUTOMATIQUEMENT LES NOTIFICATIONS (événements pour admin)
    notificationController.autoCreateNotifications().listen((_) {
      // Les notifications sont créées automatiquement
    });

    // 👈 CRÉER AUTOMATIQUEMENT LES NOTIFICATIONS DE RETARD POUR UTILISATEURS
    _retardsUtilisateurSubscription = notificationController
        .autoCreateRetardNotificationsForUsers()
        .listen((_) {
          print('🔔 Vérification des retards utilisateurs effectuée');
        });

    // 🔥 ÉCOUTER LES NOTIFICATIONS NON LUES POUR ADMIN
    _notificationsSubscription = notificationController
        .streamNotificationsNonLues()
        .listen((notifications) {
          if (notifications.isNotEmpty && mounted) {
            print('🔔 ${notifications.length} notification(s) admin non lue(s)');
          }
        });
  }

  void _showRealTimeNotification(EvenementImminent event) {
    setState(() {
      _dernierEvenement = event;
      _showNotificationBanner = true;
    });

    _animationController.forward();

    // Auto-cacher après 8 secondes
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _hideNotificationBanner();
      }
    });
  }

  void _hideNotificationBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showNotificationBanner = false;
          _dernierEvenement = null;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        // Charger les emprunts
        final empruntController = Provider.of<EmpruntController>(
          context,
          listen: false,
        );
        empruntController.chargerMesEmprunts(userId);

        await Future.delayed(const Duration(milliseconds: 500));

        // Charger les infos utilisateur
        await Provider.of<UserController>(
          context,
          listen: false,
        ).loadCurrentUser();

        // Nettoyer les anciennes notifications
        await Provider.of<NotificationController>(
          context,
          listen: false,
        ).nettoyerAnciennesNotifications();
      } catch (e) {
        print('❌ Erreur: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _evenementsSubscription.cancel();
    _notificationsSubscription.cancel();
    _retardsUtilisateurSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    final userController = Provider.of<UserController>(context);
    final notificationController = Provider.of<NotificationController>(context);
    final currentUserId = userAuth?.uid;

    final isAdmin = userController.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mediacité',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 2,
        actions: [
          // ========== CLOCHE DE NOTIFICATION POUR UTILISATEUR ==========
          if (!isAdmin && currentUserId != null)
            StreamBuilder<int>(
              stream: notificationController.getUserUnreadCountStream(currentUserId),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        // Marquer toutes les notifications utilisateur comme lues
                        await notificationController.marquerToutCommeLuPourUtilisateur(currentUserId);
                        if (context.mounted) {
                          Navigator.pushNamed(context, '/mes_notifications');
                        }
                      },
                      tooltip: count > 0
                          ? '$count notification(s) non lue(s)'
                          : 'Aucune notification',
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

          // ========== CLOCHE DE NOTIFICATION POUR ADMIN ==========
          if (isAdmin)
            StreamBuilder<int>(
              stream: notificationController.getUnreadCountStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        await notificationController.marquerToutCommeLu();
                        if (context.mounted) {
                          Navigator.pushNamed(context, '/dashboard');
                        }
                      },
                      tooltip: count > 0
                          ? '$count notification(s) non lue(s)'
                          : 'Aucune notification',
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                userAuth?.email?.split('@').first ?? 'Utilisateur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            )
          : Stack(
              children: [
                // Contenu principal
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour,',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      Text(
                        userAuth?.email?.split('@').first ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF800020),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Grille des services
                      Row(
                        children: [
                          Expanded(
                            child: _buildServiceCard(
                              context,
                              icon: Icons.inventory,
                              title: 'Catalogue',
                              description: 'Consulter les livres',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/catalogue'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildServiceCard(
                              context,
                              icon: Icons.event,
                              title: 'Événements',
                              description: 'Activités culturelles',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/evenements'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 👈 NOUVELLE CARTE MESSAGERIE
                      Row(
                        children: [
                          Expanded(
                            child: _buildMessagerieCard(
                              context,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/messagerie'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Espace pour une future carte
                          Expanded(
                            child: Container(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Carte des emprunts avec écoute en temps réel
                      Consumer<UserController>(
                        builder: (context, userController, child) {
                          final nbActifs =
                              userController.currentUser?.nbEmpruntsActifs ?? 0;
                          final limite =
                              userController.currentUser?.limiteEmprunts ?? 5;

                          return _buildStatusCard(
                            context,
                            icon: Icons.book,
                            title: 'Mes Emprunts',
                            count: nbActifs,
                            maxCount: limite,
                            subtitle: nbActifs > 0
                                ? 'Vous avez $nbActifs livre(s) en votre possession'
                                : 'Aucun emprunt en cours',
                            onTap: () =>
                                Navigator.pushNamed(context, '/emprunts'),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Section administration
                      if (isAdmin) ...[
                        const Text(
                          'Administration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildAdminCard(
                          context,
                          icon: Icons.notifications_active,
                          title: 'Notifications',
                          description: 'Gérer les alertes événements',
                          iconColor: Colors.orange,
                          badgeCount: notificationController.unreadCount,
                          onTap: () async {
                            await notificationController.marquerToutCommeLu();
                            if (context.mounted) {
                              Navigator.pushNamed(context, '/notifications');
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildAdminCard(
                          context,
                          icon: Icons.dashboard_rounded,
                          title: 'Tableau de bord',
                          description: 'Statistiques et indicateurs',
                          iconColor: const Color(0xFF003366),
                          onTap: () =>
                              Navigator.pushNamed(context, '/dashboard'),
                        ),
                        const SizedBox(height: 12),

                        _buildAdminCard(
                          context,
                          icon: Icons.people_alt,
                          title: 'Gestion Utilisateurs',
                          description: 'Comptes et permissions',
                          iconColor: const Color(0xFF800020),
                          onTap: () => Navigator.pushNamed(
                              context, '/gestion_utilisateurs'),
                        ),
                        const SizedBox(height: 12),

                        _buildAdminCard(
                          context,
                          icon: Icons.history,
                          title: 'Historique des activités',
                          description: 'Suivi global des mouvements',
                          iconColor: Colors.teal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/historique'),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Informations pratiques
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations pratiques',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.access_time,
                              'Horaires',
                              'Lun-Sam: 10h-19h / Dim: 14h-18h',
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.location_on,
                              'Adresse',
                              '12 rue de la Médiathèque, 75001 Paris',
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                                Icons.phone, 'Téléphone', '01 23 45 67 89'),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              'contact@mediacite.fr',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // BANNER DE NOTIFICATION EN TEMPS RÉEL
                if (_showNotificationBanner && _dernierEvenement != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _animation.value),
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003366), Color(0xFF800020)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dernierEvenement!.titre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_dernierEvenement!.tempsRestant} • ${_dernierEvenement!.lieu}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _hideNotificationBanner,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  // ========== WIDGETS UI ==========

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: const Color(0xFF003366)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 👈 NOUVELLE CARTE MESSAGERIE AVEC AVATAR
  Widget _buildMessagerieCard(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar avec icône de chat
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF800020)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Messagerie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Discuter avec tous',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Indicateur de nouveaux messages (optionnel)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('dateEnvoi', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                final lastMessage = snapshot.data!.docs.first;
                final data = lastMessage.data() as Map<String, dynamic>;
                final message = data['contenu'] ?? '';
                final expediteur = data['expediteurNom'] ?? '';
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.message, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$expediteur: ${message.length > 20 ? message.substring(0, 20) + '...' : message}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required int maxCount,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final bool limiteAtteinte = count >= maxCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: limiteAtteinte ? Colors.red.shade200 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF003366), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '$count / $maxCount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: limiteAtteinte ? Colors.red : const Color(0xFF800020),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              radius: 20,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF800020).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF800020), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
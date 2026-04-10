import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _nbUtilisateurs = 0;
  int _nbEvenements = 0;
  int _nbEmpruntsActifs = 0;
  int _nbEmpruntsEnRetard = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);

    try {
      final userController = Provider.of<UserController>(context, listen: false);
      _nbUtilisateurs = await userController.countUsers();

      // Événements à venir
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('evenements')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .count()
          .get();
      _nbEvenements = eventsSnapshot.count ?? 0;

      // 👈 Récupérer tous les emprunts avec statut "en cours"
      final empruntsSnapshot = await FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'en cours')
          .get();

      final maintenant = DateTime.now();
      int nbActifs = 0;
      int nbRetard = 0;

      for (var doc in empruntsSnapshot.docs) {
        final data = doc.data();
        
        // Vérifier si dateRetourPrevu existe
        if (data.containsKey('dateRetourPrevu')) {
          final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();
          
          // Vérifier si l'emprunt a des exemplaires
          final nbExemplaires = data['nbExemplaires'] ?? 1;
          
          if (nbExemplaires > 0) {
            if (dateRetour.isAfter(maintenant)) {
              // 👈 Emprunt actif (pas encore en retard)
              nbActifs++;
            } else if (dateRetour.isBefore(maintenant)) {
              // 👈 Emprunt en retard
              nbRetard++;
            }
          }
        }
      }
      
      _nbEmpruntsActifs = nbActifs;
      _nbEmpruntsEnRetard = nbRetard;

      print('📊 Dashboard chargé:');
      print('   - Utilisateurs: $_nbUtilisateurs');
      print('   - Événements: $_nbEvenements');
      print('   - Emprunts actifs (en cours, non retardés): $_nbEmpruntsActifs');
      print('   - Emprunts en retard: $_nbEmpruntsEnRetard');

    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _naviguerVersHistorique({String? filtre}) {
    Navigator.pushNamed(
      context, 
      '/historique',
      arguments: filtre,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserController>(context).isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de bord'),
          backgroundColor: const Color(0xFF003366),
        ),
        body: const Center(child: Text('Accès réservé aux administrateurs')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          IconButton(
            onPressed: _chargerDonnees,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 🔷 STATS AVEC NAVIGATION
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      children: [
                        // Carte Utilisateurs
                        _buildStatCard(
                          "Utilisateurs",
                          _nbUtilisateurs,
                          Icons.people,
                          const Color(0xFF003366),
                          onTap: () => _naviguerVersHistorique(filtre: 'users'),
                        ),
                        
                        // Carte Événements
                        _buildStatCard(
                          "Événements",
                          _nbEvenements,
                          Icons.event,
                          const Color(0xFF800020),
                          onTap: () => _naviguerVersHistorique(filtre: 'events'),
                        ),
                        
                        // 👈 Carte Emprunts Actifs (cliquable)
                        _buildStatCard(
                          "Emprunts actifs",
                          _nbEmpruntsActifs,
                          Icons.book,
                          Colors.orange,
                          onTap: () => _naviguerVersHistorique(filtre: 'actifs'),
                        ),
                        
                        // 👈 Carte Retards (cliquable)
                        _buildStatCard(
                          "Retards",
                          _nbEmpruntsEnRetard,
                          Icons.warning,
                          Colors.red,
                          onTap: () => _naviguerVersHistorique(filtre: 'retards'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 📅 ÉVÉNEMENTS À VENIR
                    _buildDerniersEvenements(),

                    const SizedBox(height: 20),

                    // ⚠️ EMPRUNTS EN RETARD
                    _buildEmpruntsEnRetard(),

                    const SizedBox(height: 20),

                    // 📚 EMPRUNTS ACTIFS
                    _buildEmpruntsActifs(),
                  ],
                ),
              ),
      ),
    );
  }

  // 👈 Carte statistique avec navigation
  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                "$value",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📅 ÉVÉNEMENTS À VENIR
  Widget _buildDerniersEvenements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evenements')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        final events = snapshot.data!.docs;

        if (events.isEmpty) {
          return _buildEmptyCard("Aucun événement à venir");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prochains événements",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 10),
            ...events.map((event) {
              final data = event.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final places = data['nombrePlaces'] ?? 0;
              final reservees = data['placesReservees'] ?? 0;
              final statut = reservees >= places ? "Complet" : "Disponible";
              final color = statut == "Complet" ? Colors.red : Colors.green;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                    child: Text(
                      "${date.day}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                  title: Text(
                    data['titre'] ?? "Sans titre",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(data['lieu'] ?? "Lieu non spécifié"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statut,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ⚠️ EMPRUNTS EN RETARD
  Widget _buildEmpruntsEnRetard() {
    final maintenant = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'en cours')  // 👈 CORRECTION: "en cours"
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        // Filtrer les emprunts en retard
        final empruntsRetard = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('dateRetourPrevu')) {  // 👈 CORRECTION: dateRetourPrevu
            final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();
            return dateRetour.isBefore(maintenant);
          }
          return false;
        }).take(3).toList();

        if (empruntsRetard.isEmpty) {
          return _buildEmptyCard("Aucun emprunt en retard");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "⚠️ Emprunts en retard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            ...empruntsRetard.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();  // 👈 CORRECTION
              final joursRetard = maintenant.difference(dateRetour).inDays;
              final nbExemplaires = data['nbExemplaires'] ?? 1;

              return GestureDetector(
                onTap: () => _naviguerVersHistorique(filtre: 'retards'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.warning, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      data['titre'] ?? "Livre inconnu",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Utilisateur: ${data['userPrenom'] ?? ''} ${data['userNom'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Retard de $joursRetard jour(s) • $nbExemplaires exemplaire(s)",
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              );
            }),
            if (empruntsRetard.length == 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => _naviguerVersHistorique(filtre: 'retards'),
                  child: const Text(
                    "Voir tous les retards",
                    style: TextStyle(color: Color(0xFF003366)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 📚 EMPRUNTS ACTIFS
  Widget _buildEmpruntsActifs() {
    final maintenant = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'en cours')  // 👈 CORRECTION: "en cours"
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingCard();

        // Filtrer les emprunts actifs (non retardés)
        final empruntsActifs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('dateRetourPrevu')) {  // 👈 CORRECTION: dateRetourPrevu
            final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();
            return dateRetour.isAfter(maintenant);
          }
          return false;
        }).take(3).toList();

        if (empruntsActifs.isEmpty) {
          return _buildEmptyCard("Aucun emprunt actif");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📚 Emprunts actifs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            ...empruntsActifs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();  // 👈 CORRECTION
              final joursRestants = dateRetour.difference(maintenant).inDays;
              final nbExemplaires = data['nbExemplaires'] ?? 1;

              return GestureDetector(
                onTap: () => _naviguerVersHistorique(filtre: 'actifs'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.book, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      data['titre'] ?? "Livre inconnu",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Utilisateur: ${data['userPrenom'] ?? ''} ${data['userNom'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Retour dans $joursRestants jour(s) • $nbExemplaires exemplaire(s)",
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              );
            }),
            if (empruntsActifs.length == 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => _naviguerVersHistorique(filtre: 'actifs'),
                  child: const Text(
                    "Voir tous les emprunts actifs",
                    style: TextStyle(color: Color(0xFF003366)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
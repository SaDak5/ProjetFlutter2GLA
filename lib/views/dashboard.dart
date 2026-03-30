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
  int _nbEmprunts = 0;
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
      
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('evenements')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .count()
          .get();
      _nbEvenements = eventsSnapshot.count ?? 0;
      
      final empruntsSnapshot = await FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'enCours')
          .count()
          .get();
      _nbEmprunts = empruntsSnapshot.count ?? 0;
      
      final retardSnapshot = await FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'enCours')
          .get();
      
      int nbRetard = 0;
      for (var doc in retardSnapshot.docs) {
        final dateRetour = (doc.data()['dateRetourPrevu'] as Timestamp).toDate();
        if (dateRetour.isBefore(DateTime.now())) nbRetard++;
      }
      _nbEmpruntsEnRetard = nbRetard;
      
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserController>(context).isAdmin;
    
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tableau de bord'), backgroundColor: const Color(0xFF003366)),
        body: const Center(child: Text('Accès réservé aux administrateurs')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        actions: [
          IconButton(onPressed: _chargerDonnees, icon: const Icon(Icons.refresh, color: Colors.white)),
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
                    // Cartes statistiques
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      children: [
                        _buildStatCard(
                          title: 'Utilisateurs',
                          value: _nbUtilisateurs,
                          icon: Icons.people,
                          color: const Color(0xFF003366),
                          onTap: () => Navigator.pushNamed(context, '/gestion_utilisateurs'),
                        ),
                        _buildStatCard(
                          title: 'Événements à venir',
                          value: _nbEvenements,
                          icon: Icons.event,
                          color: const Color(0xFF800020),
                          onTap: () => Navigator.pushNamed(context, '/evenements'),
                        ),
                        _buildStatCard(
                          title: 'Emprunts en cours',
                          value: _nbEmprunts,
                          icon: Icons.book,
                          color: const Color.fromARGB(255, 142, 121, 6),
                          onTap: () => Navigator.pushNamed(context, '/emprunts'),
                        ),
                        _buildStatCard(
                          title: 'Emprunts en retard',
                          value: _nbEmpruntsEnRetard,
                          icon: Icons.warning,
                          color: Colors.red,
                          onTap: null,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Derniers événements
                    _buildDerniersEvenements(),
                    
                    const SizedBox(height: 20),
                    
                    // Derniers emprunts
                    _buildDerniersEmprunts(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDerniersEvenements() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('evenements')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(3)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Aucun événement à venir')),
          );
        }
        
        final events = snapshot.data!.docs;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Prochains événements', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
              ),
              const Divider(height: 0),
              ...events.map((event) {
                final data = event.data();
                final date = (data['date'] as Timestamp).toDate();
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: const Icon(Icons.event, color: Color(0xFF800020), size: 18),
                  title: Text(data['titre'] ?? 'Sans titre', 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${date.day}/${date.month}/${date.year}', 
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/evenements'),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDerniersEmprunts() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('emprunts')
          .where('statut', isEqualTo: 'enCours')
          .orderBy('dateEmprunt', descending: true)
          .limit(3)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Aucun emprunt en cours')),
          );
        }
        
        final emprunts = snapshot.data!.docs;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Derniers emprunts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
              ),
              const Divider(height: 0),
              ...emprunts.map((emprunt) {
                final data = emprunt.data();
                final dateRetour = (data['dateRetourPrevu'] as Timestamp).toDate();
                final estEnRetard = dateRetour.isBefore(DateTime.now());
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: const Icon(Icons.book, color: Color(0xFF003366), size: 18),
                  title: Text(data['titre'] ?? 'Sans titre',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Retour: ${dateRetour.day}/${dateRetour.month}/${dateRetour.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: estEnRetard
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Retard', style: TextStyle(color: Colors.white, fontSize: 9)),
                        )
                      : null,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
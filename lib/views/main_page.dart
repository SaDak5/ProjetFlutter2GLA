import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../controllers/emprunt_controller.dart';
import '../controllers/user_controller.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    // Chargement des données dès l'ouverture de l'application
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        Provider.of<EmpruntController>(context, listen: false)
            .chargerMesEmprunts(userId);
        Provider.of<UserController>(context, listen: false)
            .loadCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    final userController = Provider.of<UserController>(context);
    
    // Données issues du UserController (Collection Users)
    final isAdmin = userController.isAdmin;
    final limiteEmprunts = userController.limiteEmprunts;
    final nbEmpruntsActifs = userController.currentUser?.nbEmpruntsActifs ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mediacité',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                userAuth?.email?.split('@').first ?? 'Utilisateur',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION BIENVENUE ---
            const Text(
              'Bonjour,',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
            ),
            Text(
              userAuth?.email?.split('@').first ?? 'Utilisateur',
              style: const TextStyle(fontSize: 20, color: Color(0xFF800020)),
            ),
            const SizedBox(height: 32),

            // --- GRILLE DES SERVICES ---
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Catalogue',
                    onTap: () => Navigator.pushNamed(context, '/catalogue'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildServiceCard(
                    context,
                    icon: Icons.event,
                    title: 'Événements',
                    onTap: () => Navigator.pushNamed(context, '/evenements'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- CARTE MES EMPRUNTS (Compteur synchronisé avec la DB) ---
            _buildStatusCard(
              context,
              icon: Icons.book,
              title: 'Mes Emprunts',
              count: nbEmpruntsActifs, // Utilise la valeur exacte de la collection users
              maxCount: limiteEmprunts,
              subtitle: nbEmpruntsActifs > 0 
                  ? 'Vous avez $nbEmpruntsActifs livre(s) en main' 
                  : 'Aucun emprunt en cours',
              onTap: () => Navigator.pushNamed(context, '/emprunts'),
            ),

            const SizedBox(height: 24),

            // --- 🛡️ SECTION ADMINISTRATION (Si Admin) ---
            if (isAdmin) ...[
              const Text(
                'Administration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
              ),
              const SizedBox(height: 12),
              
              _buildSimpleActionCard(
                context,
                icon: Icons.history,
                title: 'Historique des activités',
                description: 'Suivi global des mouvements',
                iconColor: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/historique'),
              ),
              const SizedBox(height: 12),

              _buildSimpleActionCard(
                context,
                icon: Icons.dashboard_rounded,
                title: 'Tableau de bord',
                description: 'Statistiques de la médiathèque',
                iconColor: const Color(0xFF003366),
                onTap: () => Navigator.pushNamed(context, '/dashboard'),
              ),
              const SizedBox(height: 12),

              _buildSimpleActionCard(
                context,
                icon: Icons.people_alt,
                title: 'Gestion Utilisateurs',
                description: 'Comptes et permissions',
                iconColor: const Color(0xFF800020),
                onTap: () => Navigator.pushNamed(context, '/gestion_utilisateurs'),
              ),
              const SizedBox(height: 24),
            ],

            // --- SECTION INFORMATIONS PRATIQUES ---
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.access_time, 'Horaires', 'Lun-Sam: 10h-19h / Dim: 14h-18h'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.location_on, 'Adresse', '12 rue de la Médiathèque, Paris'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.phone, 'Téléphone', '01 23 45 67 89'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.email, 'Email', 'contact@mediacite.fr'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION UI ---

  Widget _buildServiceCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF003366)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, {required IconData icon, required String title, required int count, required int maxCount, required String subtitle, required VoidCallback onTap}) {
    final bool limiteAtteinte = count >= maxCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: limiteAtteinte ? Colors.red.shade200 : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF003366)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(
              '$count / $maxCount', 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: limiteAtteinte ? Colors.red : const Color(0xFF800020),
                fontSize: 18
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleActionCard(BuildContext context, {required IconData icon, required String title, required String description, required Color iconColor, required VoidCallback onTap}) {
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
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
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
        Icon(icon, color: const Color(0xFF800020), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('$label : $value', style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
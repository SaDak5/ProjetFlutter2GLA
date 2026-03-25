import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libcity/models/reservation_model.dart';
import 'package:provider/provider.dart';
import '../controllers/emprunt_controller.dart';
import '../controllers/reservation_controller.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        Provider.of<EmpruntController>(context, listen: false).chargerMesEmprunts(userId);
        Provider.of<ReservationController>(context, listen: false).chargerMesReservations(userId);
      }
      Provider.of<UserController>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = Provider.of<UserController>(context).isAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mediacité',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: CircleAvatar(
                backgroundColor: const Color(0xFF800020),
                radius: 18,
                child: Text(
                  user?.email?.split('@').first[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                user?.email?.split('@').first ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
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
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            const Text(
              'Bonjour,',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            Text(
              user?.email?.split('@').first ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF800020),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez tous nos services',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // 3 Cartes principales
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      icon: Icons.inventory,
                      title: 'Catalogue',
                      description: 'Consultez notre collection',
                      onTap: () => Navigator.pushNamed(context, '/catalogue'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      icon: Icons.event,
                      title: 'Événements',
                      description: 'Découvrez nos animations',
                      onTap: () => Navigator.pushNamed(context, '/evenements'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      icon: Icons.book,
                      title: 'Emprunts',
                      description: 'Gérez vos réservations',
                      onTap: () => Navigator.pushNamed(context, '/emprunts'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cartes Emprunts et Réservations
            Row(
              children: [
                Expanded(
                  child: Consumer<EmpruntController>(
                    builder: (context, controller, child) {
                      final nbEmprunts = controller.mesEmprunts.length;
                      final nbRetards = controller.mesEmprunts.where((e) => e.estEnRetard).length;
                      
                      return _buildStatusCard(
                        context,
                        icon: Icons.book,
                        title: 'Mes Emprunts',
                        count: nbEmprunts,
                        subtitle: nbRetards > 0 ? '$nbRetards en retard' : 'Aucun retard',
                        color: nbRetards > 0 ? const Color(0xFF800020) : const Color(0xFF003366),
                        onTap: () => Navigator.pushNamed(context, '/emprunts'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<ReservationController>(
                    builder: (context, controller, child) {
                      final nbReservations = controller.mesReservations.length;
                      final nbDisponibles = controller.mesReservations
                          .where((r) => r.statut == StatusReservation.disponible)
                          .length;
                      
                      return _buildStatusCard(
                        context,
                        icon: Icons.schedule,
                        title: 'Mes Réservations',
                        count: nbReservations,
                        subtitle: nbDisponibles > 0 ? '$nbDisponibles disponible(s)' : 'En attente',
                        color: nbDisponibles > 0 ? Colors.green : const Color(0xFF003366),
                        onTap: () => Navigator.pushNamed(context, '/reservations'),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 👈 Carte ADMIN (visible seulement pour les administrateurs)
            if (isAdmin)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF800020), Color(0xFF003366)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, '/gestion_utilisateurs'),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Color(0xFF800020)),
                  ),
                  title: const Text(
                    'Administration',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Gérer les utilisateurs',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Section Informations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                  _buildInfoRow(Icons.access_time, 'Horaires', 'Lundi - Samedi: 10h - 19h\nDimanche: 14h - 18h'),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.location_on, 'Adresse', '12 rue de la Médiathèque\n75001 Paris'),
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
    required String subtitle,
    required Color color,
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
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count élément${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF800020),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF800020).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF800020),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
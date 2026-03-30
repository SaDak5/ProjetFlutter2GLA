import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalogue_controller.dart';
import '../models/catalogue_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _auth = AuthController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    // Charger les catalogues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogueController>(context, listen: false).reinitialiserRecherche();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mediacité', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await _auth.logout();
                setState(() => _user = null);
                Navigator.pushReplacementNamed(context, '/');
              },
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Connexion', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Inscription'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF800020)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenue à', style: TextStyle(color: Colors.white)),
                  const Text(
                    'Mediacité',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _user != null ? 'Bonjour ${_user!.email?.split('@').first} !' : 'Votre médiathèque numérique',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Derniers catalogues
            const Text(
              'Derniers articles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<CatalogueController>(
              builder: (context, ctrl, child) {
                if (ctrl.enChargement) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (ctrl.catalogues.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Aucun article disponible'),
                      ),
                    ),
                  );
                }
                
                // Prendre les 2 derniers catalogues
                final derniersCatalogues = ctrl.catalogues.take(2).toList();
                
                return Column(
                  children: derniersCatalogues.map((item) => _buildCatalogueCard(item)).toList(),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Informations
            const Text('Horaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.access_time, color: Color(0xFF003366)),
                title: Text('Lundi - Samedi: 10h00 - 19h00'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.access_time, color: Color(0xFF003366)),
                title: Text('Dimanche: Fermée'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Adresse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_on, color: Color(0xFF003366)),
                title: Text('Rue Mongi bali, 8070 Tunis'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.phone, color: Color(0xFF003366)),
                title: Text('+ 216 70266820'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.email, color: Color(0xFF003366)),
                title: Text('contact@mediacite.fr'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogueCard(CatalogueModel item) {
    final estDisponible = item.nbExemplairesDisponibles > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/catalogue'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.imageBase64.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(item.imageBase64),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.inventory, size: 30, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auteur: ${item.auteur}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.categorie,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF003366),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          estDisponible 
                              ? '${item.nbExemplairesDisponibles} exemplaire(s) disponible(s)'
                              : 'Indisponible',
                          style: TextStyle(
                            fontSize: 11,
                            color: estDisponible ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Flèche
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
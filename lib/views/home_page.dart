import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mediacité', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFD4AF37)),
              onPressed: () async {
                await _auth.logout();
                setState(() => _user = null);
              },
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Connexion', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenue à', style: TextStyle(color: Colors.white)),
                  const Text('Mediacité', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(
                    _user != null ? 'Bonjour !' : 'Votre médiathèque numérique',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Horaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Card(child: ListTile(leading: Icon(Icons.access_time), title: Text('Lun-Sam: 10h-19h'))),
            const SizedBox(height: 8),
            const Text('Adresse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Card(child: ListTile(leading: Icon(Icons.location_on), title: Text('12 rue de la Médiathèque, 75001'))),
          ],
        ),
      ),
    );
  }
}
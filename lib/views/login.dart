import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _auth.signIn(email: _email.text, password: _password.text);
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _showSnackBar("Connexion réussie !", Colors.green);
      Navigator.pushReplacementNamed(context, '/main_page');
    } else if (mounted) {
      _showSnackBar("Email ou mot de passe incorrect", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Bouton retour vers l'accueil (en haut à gauche)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                      tooltip: 'Retour à l\'accueil',
                    ),
                  ),
                  const Icon(Icons.menu_book, size: 80, color: Color(0xFFD4AF37)),
                  const SizedBox(height: 16),
                  const Text("Mediacité", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 48),
                  _buildTextField(_email, "Email", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_password, "Mot de passe", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ?", style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("S'inscrire", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lien retour vers l'accueil
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text(
                      "Retour à l'accueil",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
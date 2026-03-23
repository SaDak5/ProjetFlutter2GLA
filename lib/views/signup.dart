import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _auth = AuthController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nom.text.isEmpty || _prenom.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }
    if (_password.text != _confirmPassword.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.red);
      return;
    }
    if (_password.text.length < 6) {
      _showSnackBar("Mot de passe doit contenir au moins 6 caractères", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _auth.signUp(
      nom: _nom.text,
      prenom: _prenom.text,
      email: _email.text,
      password: _password.text,
    );
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _showSnackBar("Compte créé avec succès !", Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      _showSnackBar("Erreur lors de la création du compte", Colors.red);
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
                  const Icon(Icons.person_add, size: 70, color: Color(0xFFD4AF37)),
                  const SizedBox(height: 16),
                  const Text("Créer un compte", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_nom, "Nom", Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_prenom, "Prénom", Icons.person_outline)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_email, "Email", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_password, "Mot de passe", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 16),
                  _buildTextField(_confirmPassword, "Confirmer mot de passe", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("S'inscrire", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Déjà un compte ?", style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text("Se connecter", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                      ),
                    ],
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
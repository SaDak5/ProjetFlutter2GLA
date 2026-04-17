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
  bool _passwordMatch = true;

  static const Color bleuElegant = Color(0xFF2A4D8F);

  Future<void> _register() async {
    if (_nom.text.isEmpty ||
        _prenom.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.black54);
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.black54);
      return;
    }

    if (_password.text.length < 6) {
      _showSnackBar(
          "Mot de passe doit contenir au moins 6 caractères", Colors.black54);
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
      _showSuccessDialog();
    } else if (mounted) {
      _showSnackBar("Erreur lors de la création du compte", Colors.black54);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.pushReplacementNamed(context, '/main_page');
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle,
                color: Color.fromARGB(255, 22, 97, 24),
                size: 80,
              ),
              SizedBox(height: 16),
              Text(
                "Compte créé avec succès",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _updatePasswordMatch() {
    if (_confirmPassword.text.isNotEmpty) {
      setState(() {
        _passwordMatch = _confirmPassword.text == _password.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE8ECF1),
            ],
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      icon: const Icon(Icons.arrow_back, color: bleuElegant),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black12,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: bleuElegant,
                        child: Icon(Icons.person_add,
                            color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Créer un compte",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: bleuElegant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              _nom, "Nom", Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                              _prenom, "Prénom", Icons.person_outline)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(_email, "Email", Icons.email_outlined),

                  const SizedBox(height: 16),

                  // Champ mot de passe avec onChanged pour mettre à jour la vérification
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onChanged: (_) => _updatePasswordMatch(),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: bleuElegant),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black26),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: bleuElegant, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Champ confirmer mot de passe avec feedback visuel
                  TextField(
                    controller: _confirmPassword,
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _passwordMatch =
                            value.isEmpty || value == _password.text;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Confirmer mot de passe",
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: bleuElegant),
                      suffixIcon: _confirmPassword.text.isEmpty
                          ? null
                          : Icon(
                              _passwordMatch
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  _passwordMatch ? Colors.green : Colors.red,
                            ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _confirmPassword.text.isEmpty
                              ? Colors.black26
                              : (_passwordMatch ? Colors.green : Colors.red),
                          width: _confirmPassword.text.isEmpty ? 1 : 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordMatch ? bleuElegant : Colors.red,
                          width: 2,
                        ),
                      ),
                      helperText: _confirmPassword.text.isEmpty
                          ? null
                          : (_passwordMatch
                              ? "Mots de passe identiques ✓"
                              : "Mots de passe différents"),
                      helperStyle: TextStyle(
                        color: _passwordMatch ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bleuElegant,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "S'inscrire",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Déjà un compte ?"),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/login'),
                        child: const Text(
                          "Se connecter",
                          style: TextStyle(
                            color: bleuElegant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        prefixIcon: Icon(icon, color: bleuElegant),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bleuElegant, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
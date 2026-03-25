import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class GestionUtilisateursPage extends StatefulWidget {
  const GestionUtilisateursPage({Key? key}) : super(key: key);

  @override
  State<GestionUtilisateursPage> createState() => _GestionUtilisateursPageState();
}

class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserController>(context, listen: false).loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des utilisateurs',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Ajouter un utilisateur',
          ),
        ],
      ),
      body: Consumer<UserController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des utilisateurs...'),
                ],
              ),
            );
          }
          
          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadAllUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          if (controller.users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun utilisateur', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Appuyez sur + pour ajouter', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: controller.loadAllUsers,
            color: const Color(0xFF003366),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.users.length,
              itemBuilder: (context, index) => _buildUserCard(controller.users[index], controller),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUserCard(UserModel user, UserController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF800020).withOpacity(0.1),
                  radius: 24,
                  child: Text(
                    user.nom.isNotEmpty ? user.nom[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF800020),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.prenom} ${user.nom}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(user.createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role == 'admin'
                        ? const Color(0xFF800020).withOpacity(0.1)
                        : const Color(0xFF003366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role == 'admin' ? 'Admin' : 'Usager',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: user.role == 'admin' 
                          ? const Color(0xFF800020)
                          : const Color(0xFF003366),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, user),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF003366),
                    side: const BorderSide(color: Color(0xFF003366)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, user.uid),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF800020),
                    side: const BorderSide(color: Color(0xFF800020)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddDialog(BuildContext context) {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: prenomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe *',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Création en cours...', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showSnackBar(ctx, 'Le nom est requis');
                        return;
                      }
                      if (prenomCtrl.text.trim().isEmpty) {
                        _showSnackBar(ctx, 'Le prénom est requis');
                        return;
                      }
                      if (emailCtrl.text.trim().isEmpty) {
                        _showSnackBar(ctx, 'L\'email est requis');
                        return;
                      }
                      if (passwordCtrl.text.trim().isEmpty) {
                        _showSnackBar(ctx, 'Le mot de passe est requis');
                        return;
                      }
                      
                      setState(() => isLoading = true);
                      final success = await Provider.of<UserController>(ctx, listen: false).addUser(
                        email: emailCtrl.text.trim(),
                        nom: nomCtrl.text.trim(),
                        prenom: prenomCtrl.text.trim(),
                        password: passwordCtrl.text.trim(),
                      );
                      setState(() => isLoading = false);
                      
                      if (success && ctx.mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(ctx, 'Utilisateur ajouté avec succès');
                      } else if (ctx.mounted) {
                        _showSnackBar(ctx, 'Erreur lors de l\'ajout');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
  
  // 👈 CORRECTION DU DROPDOWN
  void _showEditDialog(BuildContext context, UserModel user) {
    final nomCtrl = TextEditingController(text: user.nom);
    final prenomCtrl = TextEditingController(text: user.prenom);
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role;
    bool isLoading = false;
    
    // Liste des rôles
    final List<DropdownMenuItem<String>> roleItems = const [
      DropdownMenuItem(value: 'user', child: Text('Usager')),
      DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
    ];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: prenomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  // 👈 DROPDOWN CORRIGÉ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: roleItems.any((item) => item.value == role) ? role : 'user',
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: roleItems,
                      onChanged: (value) {
                        setState(() {
                          role = value!;
                        });
                      },
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final updatedUser = UserModel(
                        uid: user.uid,
                        nom: nomCtrl.text.trim(),
                        prenom: prenomCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        role: role,
                        createdAt: user.createdAt,
                      );
                      final success = await Provider.of<UserController>(ctx, listen: false).updateUser(updatedUser);
                      setState(() => isLoading = false);
                      
                      if (success && ctx.mounted) {
                        Navigator.pop(ctx);
                        _showSnackBar(ctx, 'Utilisateur modifié avec succès');
                      } else if (ctx.mounted) {
                        _showSnackBar(ctx, 'Erreur lors de la modification');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cet utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await Provider.of<UserController>(context, listen: false).deleteUser(uid);
      if (success && mounted) {
        _showSnackBar(context, 'Utilisateur supprimé');
      }
    }
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day}/${date.month}/${date.year}';
  }
}
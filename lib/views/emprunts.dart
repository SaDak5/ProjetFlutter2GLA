import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/emprunt_controller.dart';
import '../controllers/user_controller.dart';
import '../models/emprunt_model.dart';
import '../models/user_model.dart';

class EmpruntsPage extends StatefulWidget {
  const EmpruntsPage({Key? key}) : super(key: key);

  @override
  State<EmpruntsPage> createState() => _EmpruntsPageState();
}

class _EmpruntsPageState extends State<EmpruntsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId =
          Provider.of<UserController>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        Provider.of<EmpruntController>(context, listen: false)
            .chargerMesEmprunts(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);
    final userId = userController.currentUser?.uid;
    final user = userController.currentUser;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Connectez-vous pour voir vos emprunts',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Emprunts',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user.nbEmpruntsActifs}/${user.limiteEmprunts}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Consumer<EmpruntController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.mesEmprunts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final mesEmprunts = controller.mesEmprunts
              .where((emprunt) => emprunt.userId == userId)
              .toList();

          if (mesEmprunts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun emprunt en cours',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allez dans le catalogue pour emprunter',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Voir le catalogue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.rechargerMesEmprunts(userId),
            color: const Color(0xFF003366),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: mesEmprunts.length,
              itemBuilder: (_, i) => _buildEmpruntCard(mesEmprunts[i], user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpruntCard(EmpruntModel emprunt, UserModel? currentUser) {
    final estEnRetard = emprunt.dateRetourPrevu.isBefore(DateTime.now());
    final joursRetard =
        DateTime.now().difference(emprunt.dateRetourPrevu).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête statut + nombre exemplaires
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estEnRetard
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF003366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        estEnRetard ? Icons.warning : Icons.check_circle,
                        size: 12,
                        color: estEnRetard
                            ? Colors.red
                            : const Color(0xFF003366),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estEnRetard ? 'En retard' : 'En cours',
                        style: TextStyle(
                          fontSize: 10,
                          color: estEnRetard
                              ? Colors.red
                              : const Color(0xFF003366),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${emprunt.nbExemplaires} exemplaire(s)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image + détails
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 Image en base64
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: emprunt.imageBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(emprunt.imageBase64),
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.book,
                              size: 40, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),

                // Détails texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emprunt.titre,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auteur: ${emprunt.auteur}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Emprunté: ${_formatDate(emprunt.dateEmprunt)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Retour prévu: ${_formatDate(emprunt.dateRetourPrevu)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: estEnRetard
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: estEnRetard
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (estEnRetard)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$joursRetard jour(s) de retard',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showDetailsDialog(context, emprunt),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF003366)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Voir plus de détails',
                style: TextStyle(color: Color(0xFF003366)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, EmpruntModel emprunt) {
    final estEnRetard = emprunt.dateRetourPrevu.isBefore(DateTime.now());
    final joursRestants =
        emprunt.dateRetourPrevu.difference(DateTime.now()).inDays;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book, color: Color(0xFF003366)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(emprunt.titre,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 👇 Image en base64
              if (emprunt.imageBase64.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(emprunt.imageBase64),
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Auteur', emprunt.auteur),
              const Divider(),
              _buildDetailRow(Icons.inventory, 'Nombre d\'exemplaires',
                  '${emprunt.nbExemplaires}'),
              const Divider(),
              _buildDetailRow(Icons.calendar_today, 'Date d\'emprunt',
                  _formatDateTime(emprunt.dateEmprunt)),
              const Divider(),
              _buildDetailRow(Icons.event, 'Date de retour prévue',
                  _formatDateTime(emprunt.dateRetourPrevu)),
              const Divider(),
              _buildDetailRow(
                Icons.warning,
                'Statut',
                estEnRetard
                    ? 'En retard de ${-joursRestants} jour(s)'
                    : 'Dans les délais ($joursRestants jour(s) restants)',
                color: estEnRetard ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF003366)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        color: color ?? Colors.black87,
                        fontWeight: color != null
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
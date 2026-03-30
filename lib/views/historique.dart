import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/emprunt_controller.dart';
import '../models/emprunt_model.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({Key? key}) : super(key: key);

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmpruntController>(context, listen: false).chargerTousLesEmprunts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Historique Global',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<EmpruntController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.tousLesEmprunts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }

          final listeGlobale = controller.tousLesEmprunts;

          if (listeGlobale.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun emprunt enregistré',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => controller.chargerTousLesEmprunts(),
            color: const Color(0xFF003366),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listeGlobale.length,
              itemBuilder: (context, index) {
                return _buildGlobalEmpruntCard(listeGlobale[index], controller);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalEmpruntCard(EmpruntModel emprunt, EmpruntController controller) {
    final maintenant = DateTime.now();
    final estRetourne = emprunt.statut == 'retourné';
    final estEnRetard = !estRetourne && emprunt.dateRetourPrevu.isBefore(maintenant);

    // Détermination du style selon le statut
    Color statusColor;
    String statusText;
    if (estRetourne) {
      statusColor = Colors.blue;
      statusText = 'RETOURNÉ';
    } else if (estEnRetard) {
      statusColor = Colors.red;
      statusText = 'EN RETARD';
    } else {
      statusColor = Colors.green;
      statusText = 'ACTIF';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header: ID + Statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID User: ${emprunt.userId.substring(0, 8)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Infos livre + bouton action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: emprunt.imageBase64.isNotEmpty
                      ? Image.memory(base64Decode(emprunt.imageBase64), width: 60, height: 80, fit: BoxFit.cover)
                      : Container(width: 60, height: 80, color: Colors.grey[200], child: const Icon(Icons.book)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emprunt.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Auteur: ${emprunt.auteur}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      _buildDateInfo(Icons.calendar_today, 'Pris le:', emprunt.dateEmprunt),
                      _buildDateInfo(
                        Icons.event_busy, 
                        'Retour:', 
                        emprunt.dateRetourPrevu, 
                        color: estEnRetard ? Colors.red : null
                      ),
                    ],
                  ),
                ),
                // Bouton pour retourner le livre (si pas déjà fait)
                if (!estRetourne)
                  IconButton(
                    icon: const Icon(Icons.assignment_return, color: Color(0xFF003366)),
                    onPressed: () => _showConfirmReturnDialog(emprunt, controller),
                    tooltip: 'Marquer comme retourné',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmReturnDialog(EmpruntModel emprunt, EmpruntController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le retour'),
        content: Text('Voulez-vous marquer "${emprunt.titre}" comme rendu ?\nLe stock sera automatiquement mis à jour.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await controller.retourner(emprunt.id, emprunt.catalogueId, emprunt.nbExemplaires);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Retour validé' : 'Erreur: ${controller.error}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider le retour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(IconData icon, String label, DateTime date, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label ${_formatDate(date)}',
          style: TextStyle(fontSize: 11, color: color ?? Colors.grey[600], fontWeight: color != null ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
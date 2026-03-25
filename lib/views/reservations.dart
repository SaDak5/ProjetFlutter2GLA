import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/reservation_controller.dart';
import '../controllers/user_controller.dart';
import '../models/reservation_model.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<UserController>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        Provider.of<ReservationController>(context, listen: false).chargerMesReservations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserController>(context).currentUser?.uid;
    final isLoggedIn = userId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
      ),
      body: isLoggedIn ? _buildBody() : const Center(child: Text('Connectez-vous pour voir vos réservations')),
    );
  }
  
  Widget _buildBody() {
    return Consumer<ReservationController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final userId = Provider.of<UserController>(context, listen: false).currentUser?.uid;
                    if (userId != null) {
                      controller.chargerMesReservations(userId);
                    }
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        
        if (controller.mesReservations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucune réservation en cours', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Réservez un média quand il est indisponible', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.mesReservations.length,
          itemBuilder: (_, i) => _buildReservationCard(controller.mesReservations[i]),
        );
      },
    );
  }
  
  Widget _buildReservationCard(ReservationModel r) {
    Color statusColor;
    IconData statusIcon;
    
    switch (r.statut) {
      case StatusReservation.enAttente:
        statusColor = const Color(0xFFFFD700);
        statusIcon = Icons.hourglass_empty;
        break;
      case StatusReservation.disponible:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case StatusReservation.expiree:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case StatusReservation.annulee:
        statusColor = Colors.grey;
        statusIcon = Icons.close;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: r.imageUrl.isNotEmpty
                      ? Image.network(r.imageUrl, width: 60, height: 80, fit: BoxFit.cover)
                      : Container(width: 60, height: 80, color: Colors.grey[200], child: const Icon(Icons.book)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(r.auteur, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(r.statut.libelle, style: TextStyle(fontSize: 10, color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Position dans la file', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('#${r.positionFile}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date de réservation', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text(_formatDate(r.dateReservation), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (r.statut == StatusReservation.enAttente)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _annulerReservation(r.id, r.catalogueId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                  ),
                  child: const Text('Annuler la réservation'),
                ),
              ),
            if (r.statut == StatusReservation.disponible)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _emprunter(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                  ),
                  child: const Text('Disponible - Venez emprunter'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _annulerReservation(String reservationId, String catalogueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Voulez-vous vraiment annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Non')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Oui')
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await Provider.of<ReservationController>(context, listen: false)
          .annulerReservation(reservationId, catalogueId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation annulée')),
        );
      }
    }
  }
  
  void _emprunter(ReservationModel r) {
    Navigator.pushNamed(context, '/emprunts');
  }
  
  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }
}
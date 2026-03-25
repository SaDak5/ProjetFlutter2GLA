import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/emprunt_controller.dart';
import '../controllers/user_controller.dart';
import '../models/emprunt_model.dart';
import '../models/reservation_model.dart';

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
      final userId = Provider.of<UserController>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        Provider.of<EmpruntController>(context, listen: false).chargerMesEmprunts(userId);
        Provider.of<EmpruntController>(context, listen: false).chargerMesReservations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserController>(context).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Connectez-vous pour voir vos emprunts')),
      );
    }
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Emprunts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF003366),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours', icon: Icon(Icons.book)),
              Tab(text: 'Réservations', icon: Icon(Icons.schedule)),
            ],
          ),
        ),
        body: Consumer<EmpruntController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return TabBarView(
              children: [
                _buildEmpruntsList(controller.mesEmprunts),
                _buildReservationsList(controller.mesReservations),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEmpruntsList(List<EmpruntModel> emprunts) {
    if (emprunts.isEmpty) {
      return const Center(child: Text('Aucun emprunt en cours'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: emprunts.length,
      itemBuilder: (_, i) => _buildEmpruntCard(emprunts[i]),
    );
  }
  
  Widget _buildEmpruntCard(EmpruntModel e) {
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
                  child: e.imageUrl.isNotEmpty
                      ? Image.network(e.imageUrl, width: 60, height: 80, fit: BoxFit.cover)
                      : Container(width: 60, height: 80, color: Colors.grey[200], child: const Icon(Icons.book)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(e.auteur, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Retour prévu: ${_formatDate(e.dateRetourPrevu)}'),
                      if (e.estEnRetard)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: Text('${e.joursDeRetard} jour(s) de retard', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (e.peutProlonger)
                  ElevatedButton(
                    onPressed: () => _prolonger(e.id),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                    child: const Text('Prolonger'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showCodeBarres(e.codeBarres),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                  child: const Text('QR Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReservationsList(List<ReservationModel> reservations) {
    if (reservations.isEmpty) {
      return const Center(child: Text('Aucune réservation'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reservations.length,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.schedule, color: Color(0xFF003366)),
          title: Text(reservations[i].titre),
          subtitle: Text('Position dans la file: ${reservations[i].positionFile}'),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF800020)),
            onPressed: () => _annulerReservation(
              reservations[i].id, 
              reservations[i].catalogueId
            ),
          ),
        ),
      ),
    );
  }
  
  void _prolonger(String id) async {
    final success = await Provider.of<EmpruntController>(context, listen: false).prolonger(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prolongation effectuée')));
    }
  }
  
  void _showCodeBarres(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code-barres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: code, size: 200),
            const SizedBox(height: 12),
            Text(code, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Fermer')
          ),
        ],
      ),
    );
  }
  
  void _annulerReservation(String reservationId, String catalogueId) async {
    final success = await Provider.of<EmpruntController>(context, listen: false)
        .annulerReservation(reservationId, catalogueId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation annulée')));
    }
  }
  
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
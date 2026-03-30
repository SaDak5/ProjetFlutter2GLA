import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:libcity/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/evenement_controller.dart';
import '../controllers/user_controller.dart';
import '../models/evenement_model.dart';

class EvenementsPage extends StatefulWidget {
  const EvenementsPage({Key? key}) : super(key: key);

  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  final TextEditingController _search = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _selectedType = 'Tous';
  
  final List<String> _types = ['Tous', 'Atelier', 'Conférence', 'Exposition', 'Lecture', 'Projection', 'Rencontre', 'Spectacle'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EvenementController>(context, listen: false).reinitialiserRecherche();
      Provider.of<UserController>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserController>(context).isAdmin;
    final user = Provider.of<UserController>(context).currentUser;
    final userId = user?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        actions: [
          if (isAdmin) 
            IconButton(
              onPressed: () => _addDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _rechercher(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedType,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
            ),
          ),
          Expanded(
            child: Consumer<EvenementController>(
              builder: (context, controller, child) {
                if (controller.enChargement) return const Center(child: CircularProgressIndicator());
                
                // Filtrer par type
                final items = controller.evenements
                    .where((e) => _selectedType == 'Tous' || e.type == _selectedType)
                    .toList();
                    
                if (items.isEmpty) return const Center(child: Text('Aucun événement'));
                
                // Séparer les événements en deux listes
                final maintenant = DateTime.now();
                final eventsAvenir = items.where((e) => e.date.isAfter(maintenant) || e.date.isAtSameMomentAs(maintenant)).toList();
                final eventsPasses = items.where((e) => e.date.isBefore(maintenant)).toList();
                
                // Trier les événements à venir par date croissante (du plus proche au plus loin)
                eventsAvenir.sort((a, b) => a.date.compareTo(b.date));
                // Trier les événements passés par date décroissante (du plus récent au plus ancien)
                eventsPasses.sort((a, b) => b.date.compareTo(a.date));
                
                // Fusionner les listes (à venir d'abord, puis passés)
                final eventsOrdonnes = [...eventsAvenir, ...eventsPasses];
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: eventsOrdonnes.length,
                  itemBuilder: (_, i) => _buildCard(eventsOrdonnes[i], isAdmin, userId, user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(EvenementModel e, bool isAdmin, String? userId, UserModel? user) {
    final maintenant = DateTime.now();
    final estPasse = e.date.isBefore(maintenant);
    final estComplet = e.estComplet;
    final aReserve = e.aReserve(userId ?? '');
    final placesReservees = e.getPlacesReserveesByUser(userId ?? '');
    
    return InkWell(
      onTap: () => _showDetails(e, isAdmin),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: e.imageBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(e.imageBase64),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    )
                  : Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.event, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF800020).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(e.type, style: const TextStyle(fontSize: 11, color: Color(0xFF800020))),
                      ),
                      const SizedBox(width: 8),
                      if (estPasse)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Expiré', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.titre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_formatDate(e.date))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(e.lieu, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.estGratuit ? 'Gratuit' : '${e.prix} DT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: e.estGratuit ? Colors.green : const Color(0xFF800020),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estComplet ? Colors.red : const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          estComplet ? 'Complet' : '${e.placesDisponibles} places',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton Réserver (uniquement si non passé)
                      if (!estPasse && !estComplet && !aReserve)
                        ElevatedButton(
                          onPressed: () => _reserver(e, userId, user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF800020),
                            side: const BorderSide(color: Color(0xFF800020)),
                          ),
                          child: const Text('Réserver'),
                        )
                      else if (!estPasse && aReserve)
                        ElevatedButton(
                          onPressed: () => _gestionReservation(e, userId, user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF800020),
                            side: const BorderSide(color: Color(0xFF800020)),
                          ),
                          child: Text(placesReservees > 0 ? 'Modifier ($placesReservees)' : 'Annuler'),
                        )
                      else if (estPasse)
                        const Text('Expiré', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      
                      // Boutons admin
                      if (isAdmin)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _editDialog(e),
                              icon: const Icon(Icons.edit, size: 18, color: Color(0xFF003366)),
                            ),
                            IconButton(
                              onPressed: () => _supprimer(e.id),
                              icon: const Icon(Icons.delete, size: 18, color: Color(0xFF800020)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(EvenementModel e, bool isAdmin) async {
    final controller = Provider.of<EvenementController>(context, listen: false);
    await controller.chargerParticipants(e.id);
    
    final maintenant = DateTime.now();
    final estPasse = e.date.isBefore(maintenant);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 400,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF003366),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (estPasse)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Expiré', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.imageBase64.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(e.imageBase64),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _detailRow(Icons.calendar_today, 'Date', _formatDate(e.date)),
                      _detailRow(Icons.location_on, 'Lieu', e.lieu),
                      if (e.description.isNotEmpty)
                        _detailRow(Icons.description, 'Description', e.description),
                      _detailRow(Icons.people, 'Places', '${e.placesDisponibles}/${e.nombrePlaces} disponibles'),
                      _detailRow(Icons.attach_money, 'Prix', e.estGratuit ? 'Gratuit' : '${e.prix} DT'),
                      const SizedBox(height: 16),
                      
                      // Participants (uniquement si non passé)
                      if (!estPasse && e.reservations.isNotEmpty) ...[
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<EvenementController>(
                          builder: (context, controller, child) {
                            if (controller.participantsDetails.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.participantsDetails.length,
                              itemBuilder: (_, i) {
                                final p = controller.participantsDetails[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF003366),
                                    child: Text(
                                      p['prenom']?.isNotEmpty == true
                                          ? p['prenom'][0].toUpperCase()
                                          : (p['nom']?.isNotEmpty == true ? p['nom'][0].toUpperCase() : '?'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    p['prenom'] != null && p['prenom'].isNotEmpty
                                        ? '${p['prenom']} ${p['nom']}'.trim()
                                        : p['nom'] ?? 'Utilisateur inconnu',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (p['email'] != null && p['email'].isNotEmpty)
                                        Text(p['email'], style: const TextStyle(fontSize: 12)),
                                      Text(
                                        '${p['nbPlaces']} place(s) réservée(s)',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  dense: true,
                                );
                              },
                            );
                          },
                        ),
                      ] else if (!estPasse)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucun participant pour le moment',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF003366)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _gestionReservation(EvenementModel e, String? userId, UserModel? user) async {
    if (userId == null || user == null) return;
    
    final places = e.getPlacesReserveesByUser(userId);
    final choix = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gérer - ${e.titre}'),
        content: Text('Vous avez $places place(s) réservée(s)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'annuler'), child: const Text('Annuler des places')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'ajouter'), child: const Text('Ajouter des places')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
    
    if (choix == 'annuler') _annuler(e, userId);
    else if (choix == 'ajouter') _ajouterPlaces(e, userId, user);
  }

  void _ajouterPlaces(EvenementModel e, String userId, UserModel user) async {
    int nb = 1;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Ajouter des places - ${e.titre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Places disponibles: ${e.placesDisponibles}'),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  onPressed: () => nb > 1 ? setState(() => nb--) : null,
                  icon: const Icon(Icons.remove_circle, size: 32),
                  color: const Color(0xFF800020),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text('$nb', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => nb < e.placesDisponibles ? setState(() => nb++) : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: const Color(0xFF003366),
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .reserverPlaces(e.id, nb, userId);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$nb place(s) ajoutée(s) avec succès'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _reserver(EvenementModel e, String? userId, UserModel? user) async {
    if (userId == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour réserver'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    int nb = 1;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Réserver - ${e.titre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Places disponibles: ${e.placesDisponibles}'),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  onPressed: () => nb > 1 ? setState(() => nb--) : null,
                  icon: const Icon(Icons.remove_circle, size: 32),
                  color: const Color(0xFF800020),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text('$nb', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => nb < e.placesDisponibles ? setState(() => nb++) : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: const Color(0xFF003366),
                ),
              ]),
              if (!e.estGratuit)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF800020).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 14)),
                      Text(
                        '${(e.prix * nb).toStringAsFixed(2)} DT',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800020)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .reserverPlaces(e.id, nb, userId);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$nb place(s) réservée(s) avec succès'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _annuler(EvenementModel e, String? userId) async {
    if (userId == null) return;
    final places = e.getPlacesReserveesByUser(userId);
    int nb = 1;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Annuler - ${e.titre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vous avez $places place(s) réservée(s)'),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  onPressed: () => nb > 1 ? setState(() => nb--) : null,
                  icon: const Icon(Icons.remove_circle, size: 32),
                  color: const Color(0xFF800020),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text('$nb', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => nb < places ? setState(() => nb++) : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: const Color(0xFF003366),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ces places redeviendront disponibles',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .annulerReservation(e.id, nb, userId);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$nb place(s) annulée(s)'), backgroundColor: Colors.orange),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _addDialog(BuildContext context) async {
    final titre = TextEditingController();
    final desc = TextEditingController();
    final lieu = TextEditingController();
    final adresse = TextEditingController();
    final places = TextEditingController();
    final prix = TextEditingController();
    DateTime date = DateTime.now();
    String type = 'Atelier';
    bool gratuit = false;
    File? img;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajouter un événement'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(source: ImageSource.gallery);
                      if (p != null) setState(() => img = File(p.path));
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: img != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(img!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text('Ajouter une image', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                    items: _types.where((t) => t != 'Tous').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Date et heure'),
                    subtitle: Text(_formatDate(date)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF003366)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(date),
                        );
                        if (t != null) {
                          setState(() => date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: adresse, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: places,
                    decoration: const InputDecoration(labelText: 'Nombre de places *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prix,
                          decoration: const InputDecoration(labelText: 'Prix', border: OutlineInputBorder(), prefixText: 'DT '),
                          keyboardType: TextInputType.number,
                          enabled: !gratuit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Text('Gratuit'),
                          Switch(
                            value: gratuit,
                            onChanged: (v) {
                              setState(() {
                                gratuit = v;
                                if (v) prix.text = '0';
                              });
                            },
                            activeColor: const Color(0xFF003366),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (titre.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir un titre')));
                  return;
                }
                if (lieu.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir un lieu')));
                  return;
                }
                final nbrPlaces = int.tryParse(places.text);
                if (nbrPlaces == null || nbrPlaces <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nombre de places invalide')));
                  return;
                }
                
                final ok = await Provider.of<EvenementController>(ctx, listen: false).ajouterEvenement(
                  titre: titre.text,
                  description: desc.text,
                  date: date,
                  lieu: lieu.text,
                  adresse: adresse.text,
                  nombrePlaces: nbrPlaces,
                  prix: gratuit ? 0 : double.tryParse(prix.text) ?? 0,
                  type: type,
                  image: img,
                  estGratuit: gratuit,
                );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Événement ajouté avec succès'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _editDialog(EvenementModel e) async {
    final titre = TextEditingController(text: e.titre);
    final desc = TextEditingController(text: e.description);
    final lieu = TextEditingController(text: e.lieu);
    final adresse = TextEditingController(text: e.adresse);
    final places = TextEditingController(text: e.nombrePlaces.toString());
    final prix = TextEditingController(text: e.prix.toString());
    DateTime date = e.date;
    String type = e.type;
    bool gratuit = e.estGratuit;
    File? newImg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Modifier l\'événement'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(source: ImageSource.gallery);
                      if (p != null) setState(() => newImg = File(p.path));
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: newImg != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(newImg!, fit: BoxFit.cover),
                            )
                          : (e.imageBase64.isNotEmpty 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(base64Decode(e.imageBase64), fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 40, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text('Changer l\'image', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                    items: _types.where((t) => t != 'Tous').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Date et heure'),
                    subtitle: Text(_formatDate(date)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF003366)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(date),
                        );
                        if (t != null) {
                          setState(() => date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: adresse, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: places,
                    decoration: const InputDecoration(labelText: 'Nombre de places *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prix,
                          decoration: const InputDecoration(labelText: 'Prix', border: OutlineInputBorder(), prefixText: 'DT '),
                          keyboardType: TextInputType.number,
                          enabled: !gratuit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Text('Gratuit'),
                          Switch(
                            value: gratuit,
                            onChanged: (v) {
                              setState(() {
                                gratuit = v;
                                if (v) prix.text = '0';
                              });
                            },
                            activeColor: const Color(0xFF003366),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (titre.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir un titre')));
                  return;
                }
                if (lieu.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez saisir un lieu')));
                  return;
                }
                final nbrPlaces = int.tryParse(places.text);
                if (nbrPlaces == null || nbrPlaces <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nombre de places invalide')));
                  return;
                }
                
                String base64 = e.imageBase64;
                if (newImg != null) {
                  final bytes = await newImg!.readAsBytes();
                  base64 = base64Encode(bytes);
                }
                final updated = e.copyWith(
                  titre: titre.text,
                  description: desc.text,
                  date: date,
                  lieu: lieu.text,
                  adresse: adresse.text,
                  nombrePlaces: nbrPlaces,
                  prix: gratuit ? 0 : double.tryParse(prix.text) ?? e.prix,
                  type: type,
                  estGratuit: gratuit,
                  imageBase64: base64,
                );
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .modifierEvenement(updated);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Événement modifié avec succès'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Confirmer la suppression de cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      final success = await Provider.of<EvenementController>(context, listen: false)
          .supprimerEvenement(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement supprimé'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _rechercher(BuildContext context) {
    final t = _search.text;
    if (t.isEmpty) {
      Provider.of<EvenementController>(context, listen: false).reinitialiserRecherche();
    } else {
      Provider.of<EvenementController>(context, listen: false).rechercherParTitre(t);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
}
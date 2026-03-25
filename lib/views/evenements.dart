import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
                if (controller.enChargement) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final items = controller.evenements
                    .where((e) => _selectedType == 'Tous' || e.type == _selectedType)
                    .toList();
                    
                if (items.isEmpty) {
                  return const Center(child: Text('Aucun événement'));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildCard(items[i], isAdmin),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(EvenementModel e, bool isAdmin) {
    // Utiliser les propriétés du modèle
    final bool estPasse = e.estPasse;
    final bool estComplet = e.estComplet;
    final bool aDesReservations = e.placesReservees > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: e.imageBase64.isNotEmpty
                ? Image.memory(base64Decode(e.imageBase64), height: 150, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.event, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF800020).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(e.type, style: const TextStyle(fontSize: 11, color: Color(0xFF800020))),
                ),
                const SizedBox(height: 8),
                Text(e.titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(_formatDate(e.date)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 14),
                  const SizedBox(width: 4),
                  Text(e.lieu, maxLines: 1),
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
                    // Bouton Réserver - visible seulement si non complet et non passé
                    if (!estComplet && !estPasse)
                      ElevatedButton(
                        onPressed: () => _reserver(e),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF800020),
                          side: const BorderSide(color: Color(0xFF800020)),
                        ),
                        child: const Text('Réserver'),
                      )
                    // Bouton Annuler - visible seulement si des places réservées et non passé
                    else if (aDesReservations && !estPasse)
                      ElevatedButton(
                        onPressed: () => _annuler(e),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF800020),
                          side: const BorderSide(color: Color(0xFF800020)),
                        ),
                        child: const Text('Annuler'),
                      )
                    // Message pour événement complet
                    else if (estComplet)
                      const Text(
                        'Complet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    // Message pour événement passé
                    else if (estPasse)
                      const Text(
                        'Passé',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    
                    // Boutons admin (Modifier/Supprimer)
                    if (isAdmin)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _editDialog(e),
                            child: const Icon(Icons.edit, size: 18, color: Color(0xFF003366)),
                          ),
                          TextButton(
                            onPressed: () => _supprimer(e.id),
                            child: const Icon(Icons.delete, size: 18, color: Color(0xFF800020)),
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
    );
  }

  void _reserver(EvenementModel e) async {
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
                Text('$nb', style: const TextStyle(fontSize: 24)),
                IconButton(
                  onPressed: () => nb < e.placesDisponibles ? setState(() => nb++) : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: const Color(0xFF003366),
                ),
              ]),
              if (!e.estGratuit)
                Text('Total: ${(e.prix * nb).toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .reserverPlaces(e.id, nb);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _annuler(EvenementModel e) async {
    int nb = 1;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Annuler - ${e.titre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Places réservées: ${e.placesReservees}'),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  onPressed: () => nb > 1 ? setState(() => nb--) : null,
                  icon: const Icon(Icons.remove_circle, size: 32),
                  color: const Color(0xFF800020),
                ),
                Text('$nb', style: const TextStyle(fontSize: 24)),
                IconButton(
                  onPressed: () => nb < e.placesReservees ? setState(() => nb++) : null,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: const Color(0xFF003366),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Ces places redeviendront disponibles', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .annulerReservation(e.id, nb);
                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
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
          title: const Text('Ajouter'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 80,
                      );
                      if (p != null) setState(() => img = File(p.path));
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: img != null ? Image.file(img!, fit: BoxFit.cover) : const Icon(Icons.add_photo_alternate),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre')),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _types.where((t) => t != 'Tous').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(_formatDate(date)),
                    trailing: const Icon(Icons.calendar_today),
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
                  TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu')),
                  TextField(controller: adresse, decoration: const InputDecoration(labelText: 'Adresse')),
                  TextField(controller: places, decoration: const InputDecoration(labelText: 'Places'), keyboardType: TextInputType.number),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: prix, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number)),
                      Row(children: [const Text('Gratuit'), Switch(value: gratuit, onChanged: (v) => setState(() => gratuit = v))]),
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
                final ok = await Provider.of<EvenementController>(ctx, listen: false).ajouterEvenement(
                  titre: titre.text,
                  description: desc.text,
                  date: date,
                  lieu: lieu.text,
                  adresse: adresse.text,
                  nombrePlaces: int.tryParse(places.text) ?? 0,
                  prix: gratuit ? 0 : double.tryParse(prix.text) ?? 0,
                  type: type,
                  image: img,
                  estGratuit: gratuit,
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
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
          title: const Text('Modifier'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 80,
                      );
                      if (p != null) setState(() => newImg = File(p.path));
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: newImg != null 
                        ? Image.file(newImg!, fit: BoxFit.cover) 
                        : (e.imageBase64.isNotEmpty 
                          ? Image.memory(base64Decode(e.imageBase64), fit: BoxFit.cover) 
                          : const Icon(Icons.image)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre')),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _types.where((t) => t != 'Tous').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(_formatDate(date)),
                    trailing: const Icon(Icons.calendar_today),
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
                  TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu')),
                  TextField(controller: adresse, decoration: const InputDecoration(labelText: 'Adresse')),
                  TextField(controller: places, decoration: const InputDecoration(labelText: 'Places'), keyboardType: TextInputType.number),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: prix, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number)),
                      Row(children: [const Text('Gratuit'), Switch(value: gratuit, onChanged: (v) => setState(() => gratuit = v))]),
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
                  nombrePlaces: int.tryParse(places.text) ?? e.nombrePlaces,
                  prix: gratuit ? 0 : double.tryParse(prix.text) ?? e.prix,
                  type: type,
                  estGratuit: gratuit,
                  imageBase64: base64,
                );
                final success = await Provider.of<EvenementController>(ctx, listen: false)
                    .modifierEvenement(updated);
                if (success && ctx.mounted) Navigator.pop(ctx);
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
        content: const Text('Confirmer ?'),
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
          const SnackBar(content: Text('Événement supprimé')),
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

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
}
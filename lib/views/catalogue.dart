import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/catalogue_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/emprunt_controller.dart';
import '../models/catalogue_model.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({Key? key}) : super(key: key);

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final TextEditingController _search = TextEditingController();
  String _type = 'nom';
  final ImagePicker _picker = ImagePicker();

  String _selectedCategorie = 'Tous';

  final List<String> _categoriesFiltre = [
    'Tous', 'Livres', 'Magazines', 'Films', 'BD & Mangas',
    'Jeunesse', 'Documentaires', 'CD Audio', 'Jeux vidéo',
  ];

  final List<String> _categories = [
    'Tous', 'Livres', 'Magazines', 'Films', 'BD & Mangas',
    'Jeunesse', 'Documentaires', 'CD Audio', 'Jeux vidéo',
  ];

  final List<String> _searchTypes = ['nom', 'auteur', 'nom ou auteur'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 👇 stream temps réel
      Provider.of<CatalogueController>(context, listen: false).ecouterCatalogues();
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
    final userId = Provider.of<UserController>(context).currentUser?.uid;
    final isLoggedIn = userId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catalogue',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => _addDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Ajouter un article',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: Consumer<CatalogueController>(
              builder: (context, ctrl, child) {
                if (ctrl.enChargement) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.erreur != null) {
                  return Center(child: Text(ctrl.erreur!));
                }
                final filteredItems = _filterByCategory(ctrl.catalogues);
                if (filteredItems.isEmpty) {
                  return const Center(child: Text('Aucun article'));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.start,
                    children: filteredItems.map((item) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 36) / 2,
                      child: _buildCatalogueCard(item, isAdmin, isLoggedIn, userId ?? ''),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par $_type...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              _rechercher(context);
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _rechercher(context),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.search, color: Colors.black54),
                  onSelected: (value) {
                    setState(() { _type = value; });
                    _rechercher(context);
                  },
                  itemBuilder: (_) => _searchTypes
                      .map((c) => PopupMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Recherche par: $_type',
                style: const TextStyle(fontSize: 12, color: Color(0xFF003366)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: DropdownButtonFormField<String>(
          value: _categoriesFiltre.contains(_selectedCategorie) ? _selectedCategorie : 'Tous',
          decoration: const InputDecoration(
            labelText: 'Filtrer par catégorie',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _categoriesFiltre
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            setState(() { _selectedCategorie = value!; });
            _rechercher(context);
          },
        ),
      ),
    );
  }

  List<CatalogueModel> _filterByCategory(List<CatalogueModel> items) {
    if (_selectedCategorie == 'Tous') return items;
    return items.where((item) => item.categorie == _selectedCategorie).toList();
  }

  Widget _buildCatalogueCard(
      CatalogueModel item, bool isAdmin, bool isLoggedIn, String userId) {
    final estDisponible = item.nbExemplairesDisponibles > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: item.imageBase64.isNotEmpty
                ? Image.memory(
                    base64Decode(item.imageBase64),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nom,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Auteur: ${item.auteur}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.categorie,
                      style: const TextStyle(fontSize: 9, color: Color(0xFF003366), fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.inventory, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        estDisponible
                            ? '${item.nbExemplairesDisponibles} exemplaire(s) disponible(s)'
                            : 'Indisponible',
                        style: TextStyle(
                            fontSize: 10,
                            color: estDisponible ? Colors.green : Colors.red),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: estDisponible
                          ? () => _emprunter(context, item, userId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(
                        estDisponible
                            ? 'Emprunter (${item.nbExemplairesDisponibles})'
                            : 'Indisponible',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                if (isAdmin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _editDialog(context, item),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 12, color: Color(0xFF003366)),
                            SizedBox(width: 2),
                            Text('Modifier', style: TextStyle(fontSize: 10, color: Color(0xFF003366))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      TextButton(
                        onPressed: () => _supprimer(context, item.id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 12, color: Color(0xFF800020)),
                            SizedBox(width: 2),
                            Text('Supprimer', style: TextStyle(fontSize: 10, color: Color(0xFF800020))),
                          ],
                        ),
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

  void _emprunter(BuildContext context, CatalogueModel item, String userId) async {
    int nombreExemplaires = 1;
    int maxExemplaires = item.nbExemplairesDisponibles;
    DateTime? dateRetourPrevue;
    /*final DateTime aujourdhui = DateTime.now();
    final DateTime dateMax = aujourdhui.add(const Duration(days: 21));*/
    final DateTime aujourdhui = DateTime.now();
    final DateTime dateMin = DateTime(2000);
    final DateTime dateMax = DateTime(2100);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Emprunter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Exemplaires disponibles: $maxExemplaires'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (nombreExemplaires > 1) setState(() => nombreExemplaires--);
                    },
                    icon: const Icon(Icons.remove_circle, size: 32, color: Color(0xFF800020)),
                  ),
                  Container(
                    width: 60, height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$nombreExemplaires',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      if (nombreExemplaires < maxExemplaires) setState(() => nombreExemplaires++);
                    },
                    icon: const Icon(Icons.add_circle, size: 32, color: Color(0xFF003366)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Date de retour prévue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: aujourdhui.add(const Duration(days: 14)),
                    /*firstDate: aujourdhui,
                    lastDate: dateMax,*/
                    firstDate: dateMin,
                    lastDate: dateMax,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF003366),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF003366),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => dateRetourPrevue = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateRetourPrevue == null
                            ? 'Sélectionner une date'
                            : '${dateRetourPrevue!.day}/${dateRetourPrevue!.month}/${dateRetourPrevue!.year}',
                        style: TextStyle(
                            fontSize: 14,
                            color: dateRetourPrevue == null ? Colors.grey[600] : Colors.black),
                      ),
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF003366)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Période autorisée : ${aujourdhui.day}/${aujourdhui.month}/${aujourdhui.year} - ${dateMax.day}/${dateMax.month}/${dateMax.year}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF003366)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dateRetourPrevue == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Veuillez sélectionner une date de retour'),
                    backgroundColor: Colors.orange,
                  ));
                  return;
                }
                Navigator.pop(ctx, {
                  'nbExemplaires': nombreExemplaires,
                  'dateRetour': dateRetourPrevue,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
              child: const Text('Confirmer l\'emprunt', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final empruntController = Provider.of<EmpruntController>(context, listen: false);
      final success = await empruntController.emprunterAvecDate(
        userId, item.id, result['nbExemplaires'], result['dateRetour'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Emprunt de ${result['nbExemplaires']} exemplaire(s) effectué avec succès'),
          backgroundColor: Colors.green,
        ));
      } else if (empruntController.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(empruntController.error!),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _rechercher(BuildContext context) {
    final ctrl = Provider.of<CatalogueController>(context, listen: false);
    final t = _search.text;
    if (t.isEmpty) { ctrl.reinitialiserRecherche(); return; }
    switch (_type) {
      case 'nom': ctrl.rechercherParNom(t); break;
      case 'auteur': ctrl.rechercherParAuteur(t); break;
      default: ctrl.rechercherParNomOuAuteur(t);
    }
  }

  void _addDialog(BuildContext context) {
    final nom = TextEditingController();
    final auteur = TextEditingController();
    final desc = TextEditingController();
    final nbExemplaires = TextEditingController();
    String selectedCategorie = 'Livres';
    File? img;
    bool loading = false;
    final List<String> addCategories = _categories.where((c) => c != 'Tous').toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajouter un article'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(
                          source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
                      if (p != null) setState(() => img = File(p.path));
                    },
                    child: Container(
                      height: 150, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: img != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(8),
                              child: Image.file(img!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                                Text('Tapez pour ajouter une image',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nom,
                      decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: auteur,
                      decoration: const InputDecoration(labelText: 'Auteur *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: addCategories.contains(selectedCategorie)
                          ? selectedCategorie : addCategories.first,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: addCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedCategorie = value!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nbExemplaires,
                    decoration: const InputDecoration(
                        labelText: 'Nombre d\'exemplaires *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nom.text.isEmpty) { _showSnackBar(ctx, 'Nom requis'); return; }
                if (auteur.text.isEmpty) { _showSnackBar(ctx, 'Auteur requis'); return; }
                final nbrEx = int.tryParse(nbExemplaires.text);
                if (nbrEx == null || nbrEx <= 0) {
                  _showSnackBar(ctx, 'Nombre d\'exemplaires invalide'); return;
                }
                setState(() => loading = true);
                final ctrl = Provider.of<CatalogueController>(ctx, listen: false);
                final ok = await ctrl.ajouterCatalogue(
                  nom: nom.text,
                  auteur: auteur.text,
                  description: desc.text,
                  image: img,
                  categorie: selectedCategorie,
                  nbExemplairesDisponibles: nbrEx, // ✅
                );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  _showSnackBar(ctx, 'Article ajouté avec succès');
                } else {
                  setState(() => loading = false);
                  _showSnackBar(ctx, ctrl.erreur ?? 'Erreur lors de l\'ajout');
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _editDialog(BuildContext context, CatalogueModel item) {
    final nom = TextEditingController(text: item.nom);
    final auteur = TextEditingController(text: item.auteur);
    final desc = TextEditingController(text: item.description);
    // 👇 utiliser nbExemplairesDisponibles
    final nbExemplaires = TextEditingController(text: item.nbExemplairesDisponibles.toString());
    String selectedCategorie = item.categorie;
    File? newImg;
    bool loading = false;
    bool dispo = item.estDisponible;
    final List<String> editCategories = _categories.where((c) => c != 'Tous').toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Modifier'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await _picker.pickImage(
                          source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
                      if (p != null) setState(() => newImg = File(p.path));
                    },
                    child: Container(
                      height: 150, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: newImg != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(8),
                              child: Image.file(newImg!, fit: BoxFit.cover))
                          : (item.imageBase64.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(base64Decode(item.imageBase64), fit: BoxFit.cover))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 50, color: Colors.grey[600]),
                                    Text('Tapez pour changer', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nom,
                      decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: auteur,
                      decoration: const InputDecoration(labelText: 'Auteur *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: editCategories.contains(selectedCategorie)
                          ? selectedCategorie : editCategories.first,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: editCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedCategorie = value!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nbExemplaires,
                    decoration: const InputDecoration(
                        labelText: 'Nombre d\'exemplaires disponibles', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Disponible:'),
                    Switch(value: dispo, onChanged: (v) => setState(() => dispo = v)),
                  ]),
                  if (loading) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);
                final ctrl = Provider.of<CatalogueController>(ctx, listen: false);
                String base64Img = item.imageBase64;
                if (newImg != null) {
                  final bytes = await newImg!.readAsBytes();
                  base64Img = base64Encode(bytes);
                }
                final updated = CatalogueModel(
                  id: item.id,
                  nom: nom.text,
                  auteur: auteur.text,
                  description: desc.text,
                  imageBase64: base64Img,
                  estDisponible: dispo,
                  categorie: selectedCategorie,
                  // 👇 uniquement nbExemplairesDisponibles
                  nbExemplairesDisponibles: int.tryParse(nbExemplaires.text) ?? item.nbExemplairesDisponibles,
                  dateCreation: item.dateCreation,
                );
                final ok = await ctrl.modifierCatalogue(updated);
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  _showSnackBar(ctx, 'Article modifié avec succès');
                } else {
                  setState(() => loading = false);
                  _showSnackBar(ctx, ctrl.erreur ?? 'Erreur');
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimer(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Confirmer la suppression ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      final ctrl = Provider.of<CatalogueController>(context, listen: false);
      final success = await ctrl.supprimerCatalogue(id);
      if (success && mounted) _showSnackBar(context, 'Article supprimé');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
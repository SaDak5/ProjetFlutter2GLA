import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/catalogue_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/emprunt_controller.dart';
import '../controllers/reservation_controller.dart';
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
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();
  bool _showPriceFilter = false;
  
  String _selectedCategorie = 'Tous';
  
  final List<String> _categoriesFiltre = [
    'Tous',
    'Livres',
    'Magazines',
    'Films',
    'BD & Mangas',
    'Jeunesse',
    'Documentaires',
    'CD Audio',
    'Jeux vidéo',
  ];
  
  final List<String> _categories = [
    'Tous',
    'Livres',
    'Magazines',
    'Films',
    'BD & Mangas',
    'Jeunesse',
    'Documentaires',
    'CD Audio',
    'Jeux vidéo',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogueController>(context, listen: false).reinitialiserRecherche();
      Provider.of<UserController>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _min.dispose();
    _max.dispose();
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
        bottom: _showPriceFilter ? _buildPriceFilterBar() : null,
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
                    children: filteredItems
                        .map(
                          (item) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 36) / 2,
                            child: _buildCatalogueCard(item, isAdmin, isLoggedIn, userId),
                          ),
                        )
                        .toList(),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher par $_type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
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
              color: _showPriceFilter
                  ? const Color(0xFF800020)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.attach_money,
                color: _showPriceFilter ? Colors.white : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _showPriceFilter = !_showPriceFilter;
                  if (!_showPriceFilter) {
                    _min.clear();
                    _max.clear();
                    _rechercher(context);
                  }
                });
              },
              tooltip: 'Filtrer par prix',
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
          items: _categoriesFiltre.map((categorie) {
            return DropdownMenuItem(
              value: categorie,
              child: Text(categorie),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategorie = value!;
            });
            _rechercher(context);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPriceFilterBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF003366),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _min,
                decoration: const InputDecoration(
                  labelText: 'Prix min',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'à',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _max,
                decoration: const InputDecoration(
                  labelText: 'Prix max',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final min = double.tryParse(_min.text) ?? 0;
                final max = double.tryParse(_max.text) ?? 1000;
                Provider.of<CatalogueController>(
                  context,
                  listen: false,
                ).rechercherParPrix(min, max);
                setState(() => _showPriceFilter = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800020),
                foregroundColor: Colors.white,
              ),
              child: const Text('Filtrer'),
            ),
          ],
        ),
      ),
    );
  }

  List<CatalogueModel> _filterByCategory(List<CatalogueModel> items) {
    if (_selectedCategorie == 'Tous') {
      return items;
    }
    return items.where((item) {
      switch (_selectedCategorie) {
        case 'Livres':
          return _isLivre(item.categorie);
        case 'Magazines':
          return _isMagazine(item.categorie);
        case 'Films':
          return _isFilm(item.categorie);
        case 'BD & Mangas':
          return _isBDManga(item.categorie);
        case 'Jeunesse':
          return _isJeunesse(item.categorie);
        case 'Documentaires':
          return _isDocumentaire(item.categorie);
        case 'CD Audio':
          return _isCDAudio(item.categorie);
        case 'Jeux vidéo':
          return _isJeuVideo(item.categorie);
        default:
          return true;
      }
    }).toList();
  }

  bool _isLivre(String categorie) {
    final livres = [
      'Roman', 'Roman policier', 'Roman historique', 'Roman d\'amour',
      'Roman fantastique', 'Roman science-fiction', 'Roman d\'aventure',
      'Poésie', 'Théâtre', 'Essai', 'Nouvelle', 'Conte'
    ];
    return livres.contains(categorie);
  }

  bool _isMagazine(String categorie) {
    final magazines = [
      'Actualités', 'Sciences', 'Culture', 'Mode', 'Décoration',
      'Cuisine', 'Technologie', 'Sport', 'Jeux vidéo'
    ];
    return magazines.contains(categorie);
  }

  bool _isFilm(String categorie) {
    final films = [
      'Comédie', 'Drame', 'Action', 'Thriller', 'Horreur',
      'Science-fiction', 'Fantastique', 'Romance', 'Animation',
      'Documentaire', 'Série TV'
    ];
    return films.contains(categorie);
  }

  bool _isBDManga(String categorie) {
    final bdMangas = ['Bande dessinée', 'Manga', 'Comics', 'Webtoon'];
    return bdMangas.contains(categorie);
  }

  bool _isJeunesse(String categorie) {
    final jeunesse = ['Album jeunesse', 'Roman jeunesse', 'Documentaire jeunesse', 'Contes'];
    return jeunesse.contains(categorie);
  }

  bool _isDocumentaire(String categorie) {
    final documentaires = [
      'Documentaire', 'Histoire', 'Science', 'Art', 'Philosophie',
      'Psychologie', 'Sociologie', 'Voyage', 'Nature'
    ];
    return documentaires.contains(categorie);
  }

  bool _isCDAudio(String categorie) {
    final cdAudio = [
      'Musique classique', 'Jazz', 'Rock', 'Pop', 'Hip-hop',
      'Électronique', 'Livres audio'
    ];
    return cdAudio.contains(categorie);
  }

  bool _isJeuVideo(String categorie) {
    final jeuxVideo = [
      'Action', 'Aventure', 'RPG', 'Stratégie', 'Sport', 'Simulation', 'Plateforme'
    ];
    return jeuxVideo.contains(categorie);
  }

  Widget _buildCatalogueCard(CatalogueModel item, bool isAdmin, bool isLoggedIn, String? userId) {
    final estDisponible = item.nbExemplairesDisponibles > 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
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
                    fit: BoxFit.contain,
                  )
                : Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Auteur: ${item.auteur}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.categorie,
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF003366),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prix: ${item.prix.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006400),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.inventory, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      estDisponible 
                          ? '${item.nbExemplairesDisponibles} exemplaire(s) disponible(s)'
                          : 'Indisponible',
                      style: TextStyle(
                        fontSize: 11,
                        color: estDisponible ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (isLoggedIn)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: estDisponible 
                              ? () => _emprunter(context, item, userId!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Emprunter',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reserver(context, item, userId!),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF800020)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Réserver',
                            style: TextStyle(fontSize: 12, color: Color(0xFF800020)),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 8),
                
                if (isAdmin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _editDialog(context, item),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 14, color: Color(0xFF003366)),
                            SizedBox(width: 4),
                            Text('Modifier', style: TextStyle(fontSize: 11, color: Color(0xFF003366))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _supprimer(context, item.id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete, size: 14, color: Color(0xFF800020)),
                            SizedBox(width: 4),
                            Text('Supprimer', style: TextStyle(fontSize: 11, color: Color(0xFF800020))),
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
    final controller = Provider.of<EmpruntController>(context, listen: false);
    final success = await controller.emprunter(userId, item.id, 1);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emprunt effectué avec succès')),
      );
      Provider.of<CatalogueController>(context, listen: false).reinitialiserRecherche();
    } else if (controller.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error!)),
      );
    }
  }

  void _reserver(BuildContext context, CatalogueModel item, String userId) async {
    final controller = Provider.of<ReservationController>(context, listen: false);
    final success = await controller.reserver(
      userId: userId,
      catalogueId: item.id,
      titre: item.nom,
      auteur: item.auteur,
      imageUrl: item.imageBase64,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation effectuée avec succès')),
      );
    } else if (controller.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error!)),
      );
    }
  }

  void _rechercher(BuildContext context) {
    final ctrl = Provider.of<CatalogueController>(context, listen: false);
    final t = _search.text;
    if (t.isEmpty) {
      ctrl.reinitialiserRecherche();
      return;
    }
    switch (_type) {
      case 'nom':
        ctrl.rechercherParNom(t);
        break;
      case 'auteur':
        ctrl.rechercherParAuteur(t);
        break;
      default:
        ctrl.rechercherParNomOuAuteur(t);
    }
  }

  void _addDialog(BuildContext context) {
    final nom = TextEditingController();
    final auteur = TextEditingController();
    final desc = TextEditingController();
    final prix = TextEditingController();
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
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 80,
                      );
                      if (p != null) setState(() => img = File(p.path));
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: img != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(img!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text('Tapez pour ajouter une image', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: auteur, decoration: const InputDecoration(labelText: 'Auteur *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: addCategories.contains(selectedCategorie) ? selectedCategorie : addCategories.first,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: addCategories.map((categorie) {
                        return DropdownMenuItem(
                          value: categorie,
                          child: Text(categorie),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategorie = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nbExemplaires,
                    decoration: const InputDecoration(labelText: 'Nombre d\'exemplaires *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: prix, decoration: const InputDecoration(labelText: 'Prix *', border: OutlineInputBorder(), prefixText: 'DT '), keyboardType: TextInputType.number),
                  if (loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Traitement en cours...', style: TextStyle(fontSize: 12)),
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
                if (nbrEx == null || nbrEx <= 0) { _showSnackBar(ctx, 'Nombre d\'exemplaires invalide'); return; }
                final price = double.tryParse(prix.text);
                if (price == null || price <= 0) { _showSnackBar(ctx, 'Prix invalide'); return; }

                setState(() => loading = true);
                final ctrl = Provider.of<CatalogueController>(ctx, listen: false);
                final ok = await ctrl.ajouterCatalogue(
                  nom: nom.text,
                  auteur: auteur.text,
                  description: desc.text,
                  prix: price,
                  image: img,
                  categorie: selectedCategorie,
                  nbExemplaires: nbrEx,
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
                else setState(() => loading = false);
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
    final prix = TextEditingController(text: item.prix.toString());
    final nbExemplaires = TextEditingController(text: item.nbExemplaires.toString());
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
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 80,
                      );
                      if (p != null) setState(() => newImg = File(p.path));
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: newImg != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(newImg!, fit: BoxFit.cover),
                            )
                          : (item.imageBase64.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(item.imageBase64),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 50, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text('Tapez pour changer', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: auteur, decoration: const InputDecoration(labelText: 'Auteur *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: editCategories.contains(selectedCategorie) ? selectedCategorie : editCategories.first,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: editCategories.map((categorie) {
                        return DropdownMenuItem(
                          value: categorie,
                          child: Text(categorie),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategorie = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nbExemplaires,
                    decoration: const InputDecoration(labelText: 'Nombre d\'exemplaires *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: prix, decoration: const InputDecoration(labelText: 'Prix *', border: OutlineInputBorder(), prefixText: 'DT '), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  Row(children: [const Text('Disponible:'), Switch(value: dispo, onChanged: (v) => setState(() => dispo = v))]),
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
                setState(() => loading = true);
                final ctrl = Provider.of<CatalogueController>(ctx, listen: false);
                String base64 = item.imageBase64;
                if (newImg != null) {
                  final bytes = await newImg!.readAsBytes();
                  base64 = base64Encode(bytes);
                }
                final updated = item.copyWith(
                  nom: nom.text,
                  auteur: auteur.text,
                  description: desc.text,
                  prix: double.tryParse(prix.text) ?? item.prix,
                  imageBase64: base64,
                  estDisponible: dispo,
                  categorie: selectedCategorie,
                  nbExemplaires: int.tryParse(nbExemplaires.text) ?? item.nbExemplaires,
                );
                final ok = await ctrl.modifierCatalogue(updated);
                if (ok && ctx.mounted) Navigator.pop(ctx);
                else setState(() => loading = false);
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
      await Provider.of<CatalogueController>(context, listen: false).supprimerCatalogue(id);
      if (mounted) {
        _showSnackBar(context, 'Article supprimé');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
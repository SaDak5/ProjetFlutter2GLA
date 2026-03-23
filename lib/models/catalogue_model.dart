import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CatalogueModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;      // URL Firestore après upload
  final DateTime createdAt;
  final bool isAvailable;
  
  // Attribut temporaire pour l'upload (non stocké dans Firestore)
  File? localImage;
  
  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
    this.isAvailable = true,
    this.localImage,
  });
  
  // Constructeur vide pour formulaire
  CatalogueModel.empty({
    String? id,
  }) : this(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: '',
    description: '',
    price: 0.0,
    imageUrl: '',
    createdAt: DateTime.now(),
    isAvailable: true,
  );
  
  factory CatalogueModel.fromMap(Map<String, dynamic> data, String id) {
    return CatalogueModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
    };
  }
  
  // Méthode pour uploader l'image vers Firebase Storage
  Future<String> uploadImage() async {
    if (localImage == null) return imageUrl;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('catalogues')
          .child('$id.jpg');
      
      await storageRef.putFile(localImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur upload image: $e');
    }
  }
  
  CatalogueModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    DateTime? createdAt,
    bool? isAvailable,
    File? localImage,
  }) {
    return CatalogueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      localImage: localImage ?? this.localImage,
    );
  }
}
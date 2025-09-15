// models/pet_moodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    this.notes,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'notes': notes,
      'imageUrl': imageUrl, 
      'createdAt': createdAt,
    };
  }

  static Pet fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      notes: data['notes'],
      imageUrl: data['imageUrl'], 
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? breed,
    int? age,
    String? notes,
    String? imageUrl, 
    DateTime? createdAt,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl, 
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
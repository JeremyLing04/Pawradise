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

  // // 模拟数据工厂方法
  // factory Pet.mock() {
  //   return Pet(
  //     id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}',
  //     ownerId: 'mock_user_id',
  //     name: 'Buddy',
  //     breed: 'Golden Retriever',
  //     age: 3,
  //     notes: 'Loves to play fetch. Allergic to chicken.',
  //     createdAt: DateTime.now().subtract(Duration(days: 365)),
  //   );
  // }

  // // 模拟宠物列表
  // static List<Pet> mockPets() {
  //   return [
  //     Pet.mock(),
  //     Pet(
  //       id: 'mock_pet_2',
  //       ownerId: 'mock_user_id',
  //       name: 'Milo',
  //       breed: 'Corgi',
  //       age: 2,
  //       notes: 'Very energetic in the morning.',
  //       createdAt: DateTime.now().subtract(Duration(days: 200)),
  //     ),
  //   ];
  // }

  // 转换为 Map 用于 Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'notes': notes,
      'imageUrl': imageUrl, // 新增
      'createdAt': createdAt,
    };
  }

  // 从 Firestore 文档创建 Pet 对象
  static Pet fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      notes: data['notes'],
      imageUrl: data['imageUrl'], // 新增
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // 复制方法用于编辑
  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? breed,
    int? age,
    String? notes,
    String? imageUrl, // 新增
    DateTime? createdAt,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl, // 新增
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
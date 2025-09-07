// models/pet_moodel.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final String? notes;
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    this.notes,
    required this.createdAt,
  });

  // 模拟数据工厂方法
  factory Pet.mock() {
    return Pet(
      id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: 'mock_user_id',
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: 3,
      notes: 'Loves to play fetch. Allergic to chicken.',
      createdAt: DateTime.now().subtract(Duration(days: 365)),
    );
  }

  // 模拟宠物列表
  static List<Pet> mockPets() {
    return [
      Pet.mock(),
      Pet(
        id: 'mock_pet_2',
        ownerId: 'mock_user_id',
        name: 'Milo',
        breed: 'Corgi',
        age: 2,
        notes: 'Very energetic in the morning.',
        createdAt: DateTime.now().subtract(Duration(days: 200)),
      ),
    ];
  }

  // 为Firebase准备的方法（先注释，等Firebase好了取消注释）
  /*
  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      ownerId: data['ownerId'],
      name: data['name'],
      breed: data['breed'],
      age: data['age'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  */
}
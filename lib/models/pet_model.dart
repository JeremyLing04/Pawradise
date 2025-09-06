// models/pet_moodel.dart
// import 'package:cloud_firestore/cloud_firestore.dart'; 
class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final String? notes; //can be null
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

  //mock
  factory Pet.mock({String? id, String? ownerId}){
    return Pet(
      id: id ?? 'mock_pet_id_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId ?? 'mock_user_id_123456', // 默认关联到上面的模拟用户
      name: 'Buddy',
      breed: 'Golden Retriever',
      age: 3,
      notes: 'Loves to play fetch. Allergic to chicken.',
      createdAt: DateTime.now().subtract(Duration(days: 100)),
    );
  }

  static List<Pet> mockPets(){
    return [
      Pet.mock(),
      Pet(
        id: 'mock_pet_id_2',
        ownerId: 'mock_user_id_123456',
        name: 'Milo',
        breed: 'Corgi',
        age: 2,
        notes: 'Very energetic in the morning.',
        createdAt: DateTime.now().subtract(Duration(days: 50)),
      ),
    ];
  }

  //// ✅ 为Firebase准备的方法
  // factory PetProfile.fromFirestore(Map<String, dynamic> doc, String id) {
  //   return PetProfile(
  //     id: id,
  //     ownerId: doc['ownerId'],
  //     name: doc['name'],
  //     breed: doc['breed'],
  //     age: doc['age'],
  //     notes: doc['notes'],
  //     createdAt: (doc['createdAt'] as Timestamp).toDate(),
  //   );
  // }

  // // ✅ 为Firebase准备的方法
  // Map<String, dynamic> toMap() {
  //   return {
  //     'ownerId': ownerId,
  //     'name': name,
  //     'breed': breed,
  //     'age': age,
  //     'notes': notes,
  //     'createdAt': Timestamp.fromDate(createdAt),
  //   };
  // }
}
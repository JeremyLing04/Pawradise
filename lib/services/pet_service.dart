// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/pet_model.dart';

// class PetService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // 获取用户的所有宠物
//   Stream<List<Pet>> getPets(String userId) {
//     return _firestore
//         .collection('pets')
//         .where('ownerId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) =>
//             snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList());
//   }

//   // 添加新宠物
//   Future<void> addPet(Pet pet) async {
//     await _firestore.collection('pets').add(pet.toMap());
//   }

//   // 更新宠物信息
//   Future<void> updatePet(Pet pet) async {
//     await _firestore.collection('pets').doc(pet.id).update(pet.toMap());
//   }

//   // 删除宠物
//   Future<void> deletePet(String petId) async {
//     await _firestore.collection('pets').doc(petId).delete();
//   }

//   // 获取单个宠物
//   Future<Pet?> getPet(String petId) async {
//     final doc = await _firestore.collection('pets').doc(petId).get();
//     return doc.exists ? Pet.fromFirestore(doc) : null;
//   }
// }
// services/pet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 同步获取用户的所有宠物
  Future<List<Pet>> getPetsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Pet.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pets: $e');
    }
  }

  // 实时监听用户宠物的变化（Stream方式）
  Stream<List<Pet>> getPetsByUserStream(String userId) {
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromFirestore(doc))
            .toList());
  }

  // 添加宠物
  Future<void> addPet(Pet pet, {File? imageFile}) async {
    try {
      String imageUrl = '';
      
      // 上传图片
      if (imageFile != null) {
        final ref = _storage.ref().child('pet_images/${pet.id}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // 添加到Firestore
      await _firestore.collection('pets').doc(pet.id).set({
        'ownerId': pet.ownerId,
        'name': pet.name,
        'breed': pet.breed,
        'age': pet.age,
        'notes': pet.notes,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(pet.createdAt),
      });
    } catch (e) {
      throw Exception('Failed to add pet: $e');
    }
  }

  // 更新宠物
  Future<void> updatePet(Pet pet, {File? imageFile}) async {
    try {
      String imageUrl = pet.imageUrl ?? '';
      
      // 上传新图片
      if (imageFile != null) {
        final ref = _storage.ref().child('pet_images/${pet.id}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // 更新Firestore
      await _firestore.collection('pets').doc(pet.id).update({
        'name': pet.name,
        'breed': pet.breed,
        'age': pet.age,
        'notes': pet.notes,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update pet: $e');
    }
  }

  // 删除宠物
  Future<void> deletePet(String petId, String? imageUrl) async {
    try {
      // 删除图片
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
      
      // 删除Firestore文档
      await _firestore.collection('pets').doc(petId).delete();
    } catch (e) {
      throw Exception('Failed to delete pet: $e');
    }
  }
}
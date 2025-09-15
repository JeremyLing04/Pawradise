import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Flag for index errors (optional, not currently used)
  bool _hasIndexError = false;

  /// Real-time stream of all pets belonging to a user
  /// Sorts pets on the client side by creation date (descending)
  Stream<List<Pet>> getPetsByUserStream(String userId) {
    try {
      return _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final pets = snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
            // Client-side sorting by creation date descending
            pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return pets;
          })
          .handleError((error) {
            print('Error in pet stream: $error');
            return <Pet>[];
          });
    } catch (e) {
      print('Exception in getPetsByUserStream: $e');
      return Stream.value(<Pet>[]);
    }
  }

  /// Synchronous fetch of all pets belonging to a user
  /// Returns a list sorted by creation date (descending)
  Future<List<Pet>> getPetsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: userId)
          .get();

      final pets = querySnapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();

      // Client-side sorting
      pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pets;
    } catch (e) {
      print('Error getting pets: $e');
      return [];
    }
  }

  /// Add a new pet, optionally with an image
  Future<void> addPet(Pet pet, {File? imageFile}) async {
    try {
      String imageUrl = '';

      // Upload image to Firebase Storage
      if (imageFile != null) {
        final ref = _storage.ref().child('pet_images/${pet.id}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // Save pet data to Firestore
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

  /// Update existing pet, optionally with a new image
  Future<void> updatePet(Pet pet, {File? imageFile}) async {
    try {
      String imageUrl = pet.imageUrl ?? '';

      // Upload new image if provided
      if (imageFile != null) {
        final ref = _storage.ref().child('pet_images/${pet.id}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // Update Firestore document
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

  /// Delete a pet and optionally its image
  Future<void> deletePet(String petId, String? imageUrl) async {
    try {
      // Delete image from Firebase Storage
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }

      // Delete Firestore document
      await _firestore.collection('pets').doc(petId).delete();
    } catch (e) {
      throw Exception('Failed to delete pet: $e');
    }
  }
}

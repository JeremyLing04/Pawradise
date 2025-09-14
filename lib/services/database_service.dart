import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addEvent(Event event) async {
    await _db
        .collection('users')
        .doc(event.userId)
        .collection('events')
        .doc(event.id)
        .set(event.toMap());
  }

  Future<void> updateEvent(Event event) async {
    await _db
        .collection('users')
        .doc(event.userId)
        .collection('events')
        .doc(event.id)
        .update(event.toMap());
  }

  Future<void> deleteEvent(String userId, String eventId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  Future<List<Event>> getEvents(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('events')
        .orderBy('scheduledTime')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // 确保 event.id 正确
      return Event.fromMap(data);
    }).toList();
  }
}

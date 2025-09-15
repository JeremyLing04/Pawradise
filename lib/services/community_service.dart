//screens/services/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import 'package:intl/intl.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> shareEventToCommunity(Event event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'] ?? 'Pet Owner';

      final post = PostModel.createNew(
        authorId: user.uid,
        authorName: username,
        title: '${event.type.displayName}: ${event.title}',
        content: _generateEventContent(event),
        type: 'event',
        hasImage: false,
        imageUrl: '',
        eventTime: event.scheduledTime,
        eventDescription: event.description ?? 'Join me for this pet activity!',
        eventType: event.type.toString().split('.').last,
      );

      final postRef = await _firestore.collection('posts').add(post.toMap());
      
      await _firestore
          .collection('users')
          .doc(event.userId)
          .collection('events')
          .doc(event.id)
          .update({
            'sharedToCommunity': true,
            'communityPostId': postRef.id,
          });
    } catch (e) {
      debugPrint('Error sharing event to community: $e');
    }
  }

  String _generateEventContent(Event event) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    String joinText = '';

    switch (event.type) {
      case EventType.walk:
        joinText = 'Click "Join" to walk together!';
        break;
      case EventType.vet:
        joinText = 'Click "Join" if you also have a vet appointment!';
        break;
      case EventType.feeding:
        joinText = 'Click "Join" to feed your pets together!';
        break;
      case EventType.training:
        joinText = 'Click "Join" to train together!';
        break;
      case EventType.grooming:
        joinText = 'Click "Join" for grooming session!';
        break;
      case EventType.medication:
        joinText = 'Click "Join" for medication reminder!';
        break;
      default:
        joinText = 'Click "Join" to participate!';
    }

    return '''
${event.type.displayName} Activity

**Time:** ${timeFormat.format(event.scheduledTime)} on ${dateFormat.format(event.scheduledTime)}

**Activity:** ${event.title}

**Details:** ${event.description ?? 'Join me for this pet activity!'}

$joinText
''';
  }

  Future<void> joinEvent(String postId, String eventId, BuildContext context, {
    required String eventTitle,
    required DateTime eventTime,
    required String eventDescription,
    required String authorName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final existingJoin = await _firestore
          .collection('event_participants')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingJoin.docs.isNotEmpty) {
        await _firestore
            .collection('event_participants')
            .doc(existingJoin.docs.first.id)
            .delete();

        await _deleteJoinedEvent(user.uid, postId);

        await _firestore.collection('posts').doc(postId).update({
          'participants': FieldValue.increment(-1),
        });
      } else {
        await _createJoinedEvent(
          userId: user.uid,
          postId: postId,
          eventTitle: eventTitle,
          eventTime: eventTime,
          eventDescription: eventDescription,
          authorName: authorName,
        );

        await _firestore.collection('event_participants').add({
          'postId': postId,
          'eventId': eventId,
          'userId': user.uid,
          'joinedAt': Timestamp.now(),
        });

        await _firestore.collection('posts').doc(postId).update({
          'participants': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error joining/unjoining event: $e');
    }
  }

  Future<bool> isUserJoined(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('event_participants')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking join status: $e');
      return false;
    }
  }

  Future<List<String>> getEventParticipants(String eventId) async {
    final snapshot = await _firestore
        .collection('event_participants')
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs.map((doc) => doc['userId'] as String).toList();
  }

  Future<int> getParticipantCount(String postId) async {
    final snapshot = await _firestore
        .collection('event_participants')
        .where('postId', isEqualTo: postId)
        .get();

    return snapshot.docs.length;
  }

  Future<void> _createJoinedEvent({
    required String userId,
    required String postId,
    required String eventTitle,
    required DateTime eventTime,
    required String eventDescription,
    required String authorName,
  }) async {
    try {
      final event = Event(
        id: 'joined_${postId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        petId: 'default_pet_id',
        title: 'Joined: $eventTitle',
        description: 'Joined activity from $authorName\n\n$eventDescription',
        type: EventType.other,
        scheduledTime: eventTime,
        isCompleted: false,
        createdAt: DateTime.now(),
        notificationMinutes: 30,
        sharedToCommunity: false,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('joined_events')
          .doc(event.id)
          .set(event.toMap());

    } catch (e) {
      debugPrint('Error creating joined event: $e');
    }
  }

  Map<String, dynamic> _parseEventInfoFromPost(PostModel post) {
    final result = {
      'scheduledTime': DateTime.now().add(Duration(hours: 1)), // 默认时间
      'description': post.content
    };

    try {
      final timeMatch = RegExp(r'Time:\s*(.*?)\n').firstMatch(post.content);
      final dateMatch = RegExp(r'on\s*(.*?)\n').firstMatch(post.content);
      
      if (timeMatch != null && dateMatch != null) {
        final timeStr = timeMatch.group(1)?.trim();
        final dateStr = dateMatch.group(1)?.trim();
        
        if (timeStr != null && dateStr != null) {
          final dateFormat = DateFormat('MMM d, yyyy');
          final timeFormat = DateFormat('hh:mm a');
          
          final date = dateFormat.parse(dateStr);
          final time = timeFormat.parse(timeStr);
          
          final scheduledTime = DateTime(
            date.year, date.month, date.day,
            time.hour, time.minute
          );
          
          result['scheduledTime'] = scheduledTime;
        }
      }
    } catch (e) {
      debugPrint('Error parsing event time: $e');
    }

    return result;
  }

  Future<void> _deleteJoinedEvent(String userId, String postId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('joined_events')
          .where('id', isGreaterThanOrEqualTo: 'joined_${postId}_')
          .where('id', isLessThan: 'joined_${postId}_z')
          .get();

      for (final doc in eventsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting joined event: $e');
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get existing chat room or create a new one
  Future<String> getOrCreateChatRoom(String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final participants = [currentUser.uid, otherUserId]..sort();
    final roomId = participants.join('_');

    // Check if the chat room already exists
    final existingRoom = await _firestore.collection('chatRooms').doc(roomId).get();

    if (!existingRoom.exists) {
      // Create a new chat room
      await _firestore.collection('chatRooms').doc(roomId).set({
        'participantIds': participants,
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? currentUser.email ?? 'User',
          otherUserId: otherUserName
        },
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageTime': Timestamp.now(),
        'unreadCount': 0,
        'lastMessageSenderId': '',
        'createdAt': Timestamp.now(),
      });
    }

    return roomId;
  }

  /// Send a text message
  Future<void> sendMessage(String chatRoomId, String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Add message to subcollection
    await _firestore.collection('chatRooms').doc(chatRoomId).collection('messages').add({
      'senderId': currentUser.uid,
      'senderName': currentUser.displayName ?? currentUser.email ?? 'User',
      'content': content,
      'type': 'text',
      'timestamp': Timestamp.now(),
      'read': false,
    });

    // Update last message info in the chat room
    await _updateChatRoomLastMessage(chatRoomId, content, 'text', currentUser.uid);
  }

  /// Send an image message
  Future<void> sendImageMessage(String chatRoomId, File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      // Upload image to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('chat_images').child(chatRoomId).child(fileName);

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get image download URL
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Save message to Firestore
      await _firestore.collection('chatRooms').doc(chatRoomId).collection('messages').add({
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? currentUser.email ?? 'User',
        'content': imageUrl,
        'type': 'image',
        'timestamp': Timestamp.now(),
        'read': false,
      });

      // Update last message info
      await _updateChatRoomLastMessage(chatRoomId, '[Image]', 'image', currentUser.uid);

    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
  }

  /// Update last message information in chat room (private method)
  Future<void> _updateChatRoomLastMessage(
      String chatRoomId, String content, String type, String senderId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final updateData = {
      'lastMessage': content,
      'lastMessageType': type,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': senderId,
    };

    // Increment unread count for the receiver
    if (senderId != currentUser.uid) {
      updateData['unreadCount'] = FieldValue.increment(1);
    } else {
      // For sender, also increment so receiver can see it
      updateData['unreadCount'] = FieldValue.increment(1);
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).update(updateData);
  }

  /// Get all chat rooms of the current user
  Stream<QuerySnapshot> getUserChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Get messages for a specific chat room
  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Mark all messages in a chat room as read
  Future<void> markAsRead(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Reset chat room unread count
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'unreadCount': 0,
    });

    // Mark messages as read
    final unreadMessages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUser.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }

    if (unreadMessages.docs.isNotEmpty) await batch.commit();
  }

  /// Get total unread message count across all chat rooms
  Stream<int> getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold(0, (total, doc) {
        final data = doc.data() as Map<String, dynamic>;
        final lastSender = data['lastMessageSenderId'] ?? '';
        final unreadCount = data['unreadCount'] ?? 0;

        // Count only messages sent by others
        if (lastSender != currentUser.uid) return total + (unreadCount as int);
        return total;
      });
    });
  }

  /// Get unread message count for a specific chat room
  Stream<int> getChatRoomUnreadCount(String chatRoomId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore.collection('chatRooms').doc(chatRoomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastSender = data['lastMessageSenderId'] ?? '';
      final unreadCount = data['unreadCount'] ?? 0;

      return lastSender != currentUser.uid ? unreadCount as int : 0;
    });
  }

  /// Delete a chat room and all its messages
  Future<void> deleteChatRoom(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Delete all messages in the room
    final messages = await _firestore.collection('chatRooms').doc(chatRoomId).collection('messages').get();
    final batch = _firestore.batch();

    for (final doc in messages.docs) batch.delete(doc.reference);

    // Delete the chat room document itself
    batch.delete(_firestore.collection('chatRooms').doc(chatRoomId));

    await batch.commit();
  }
}

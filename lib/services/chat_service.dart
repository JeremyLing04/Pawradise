import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 获取或创建聊天室
  Future<String> getOrCreateChatRoom(String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final participants = [currentUser.uid, otherUserId]..sort();
    final roomId = participants.join('_');

    // 检查聊天室是否已存在
    final existingRoom = await _firestore.collection('chatRooms').doc(roomId).get();
    
    if (!existingRoom.exists) {
      // 创建新聊天室
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

  // 发送文本消息
  Future<void> sendMessage(String chatRoomId, String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // 添加消息到子集合
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'senderName': currentUser.displayName ?? currentUser.email ?? 'User',
          'content': content,
          'type': 'text',
          'timestamp': Timestamp.now(),
          'read': false,
        });

    // 更新聊天室最后消息信息
    await _updateChatRoomLastMessage(
      chatRoomId,
      content,
      'text',
      currentUser.uid,
    );
  }

  // 发送图片消息
  Future<void> sendImageMessage(String chatRoomId, File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      // 1. 上传图片到 Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('chat_images')
          .child(chatRoomId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      // 2. 获取图片下载URL
      final String imageUrl = await snapshot.ref.getDownloadURL();

      // 3. 保存消息到 Firestore
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName ?? currentUser.email ?? 'User',
            'content': imageUrl,
            'type': 'image',
            'timestamp': Timestamp.now(),
            'read': false,
          });

      // 4. 更新聊天室最后消息信息
      await _updateChatRoomLastMessage(
        chatRoomId,
        '[Image]',
        'image',
        currentUser.uid,
      );

    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
  }

  // 更新聊天室最后消息信息（私有方法）
  Future<void> _updateChatRoomLastMessage(
    String chatRoomId, 
    String content, 
    String type, 
    String senderId
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final updateData = {
      'lastMessage': content,
      'lastMessageType': type,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': senderId,
    };

    // 如果发送者不是当前用户（理论上不会发生），或者接收者查看消息时增加未读计数
    if (senderId != currentUser.uid) {
      updateData['unreadCount'] = FieldValue.increment(1);
    } else {
      // 如果是自己发送的消息，重置未读计数（因为接收方需要看到）
      updateData['unreadCount'] = FieldValue.increment(1);
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).update(updateData);
  }

  // 获取用户的所有聊天室
  Stream<QuerySnapshot> getUserChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // 获取聊天室消息
  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 标记消息为已读
  Future<void> markAsRead(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. 更新聊天室的未读计数
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'unreadCount': 0,
    });

    // 2. 标记所有未读消息为已读
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

    if (unreadMessages.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // 获取未读消息总数
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
        
        // 只计算别人发送的未读消息
        if (lastSender != currentUser.uid) {
          return total + (unreadCount as int);
        }
        return total;
      });
    });
  }

  // 获取特定聊天室的未读消息数量
  Stream<int> getChatRoomUnreadCount(String chatRoomId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final lastSender = data['lastMessageSenderId'] ?? '';
      final unreadCount = data['unreadCount'] ?? 0;
      
      // 只计算别人发送的未读消息
      if (lastSender != currentUser.uid) {
        return unreadCount as int;
      }
      return 0;
    });
  }

  // 删除聊天室
  Future<void> deleteChatRoom(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 首先删除所有消息
    final messages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // 然后删除聊天室本身
    batch.delete(_firestore.collection('chatRooms').doc(chatRoomId));

    await batch.commit();
  }
}
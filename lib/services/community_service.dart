//screens/services/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

      // 获取用户信息
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'] ?? 'Pet Owner';

      // 生成帖子内容
      final content = _generateEventContent(event);
      final title = '${event.type.displayName}: ${event.title}';

      // 创建社区帖子
      final post = PostModel.createNew(
        authorId: user.uid,
        authorName: username,
        title: title,
        content: content,
        type: 'event',
        hasImage: false,
        imageUrl: '',
      );

      // 保存到社区
      final postRef = await _firestore.collection('posts').add(post.toMap());
      
      // 更新事件的分享状态并记录帖子ID
      await _firestore
          .collection('users')
          .doc(event.userId)
          .collection('events')
          .doc(event.id)
          .update({
            'sharedToCommunity': true,
            'communityPostId': postRef.id, // 保存社区帖子ID
          });
    } catch (e) {
      debugPrint('Error sharing event to community: $e');
    }
  }

  String _generateEventContent(Event event) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    String joinText = '';

    // 根据不同活动类型生成不同的加入文本
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

  // 加入活动
  Future<void> joinEvent(String postId, String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 检查是否已经加入
      final existingJoin = await _firestore
          .collection('event_participants')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingJoin.docs.isNotEmpty) {
        // 如果已经加入，则取消加入
        await _firestore
            .collection('event_participants')
            .doc(existingJoin.docs.first.id)
            .delete();

        // 更新参与计数
        await _firestore.collection('posts').doc(postId).update({
          'participants': FieldValue.increment(-1),
        });
      } else {
        // 添加到参与列表
        await _firestore.collection('event_participants').add({
          'postId': postId,
          'eventId': eventId,
          'userId': user.uid,
          'joinedAt': Timestamp.now(),
        });

        // 更新参与计数
        await _firestore.collection('posts').doc(postId).update({
          'participants': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error joining/unjoining event: $e');
    }
  }

  // 检查用户是否已加入活动
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
}
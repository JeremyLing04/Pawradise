import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 关注用户
  Future<void> followUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('用户未登录');

    final batch = _firestore.batch();
    
    // 在 friendships collection 中添加关系
    final friendshipRef = _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId');
    
    batch.set(friendshipRef, {
      'followerId': currentUser.uid,
      'followingId': targetUserId,
      'createdAt': Timestamp.now(),
      'status': 'active',
    });

    // 更新用户的关注和粉丝计数
    batch.update(_firestore.collection('users').doc(currentUser.uid), {
      'followingCount': FieldValue.increment(1),
    });
    
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // 取消关注
  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('用户未登录');

    final batch = _firestore.batch();
    
    // 删除 friendship 文档
    final friendshipRef = _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId');
    
    batch.delete(friendshipRef);

    // 更新计数
    batch.update(_firestore.collection('users').doc(currentUser.uid), {
      'followingCount': FieldValue.increment(-1),
    });
    
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // 检查是否已关注
  Future<bool> isFollowing(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final friendshipDoc = await _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId')
        .get();

    return friendshipDoc.exists;
  }

  // 获取用户的粉丝列表
  Stream<QuerySnapshot> getFollowers(String userId) {
    return _firestore
        .collection('friendships')
        .where('followingId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // 获取用户关注的人列表
  Stream<QuerySnapshot> getFollowing(String userId) {
    return _firestore
        .collection('friendships')
        .where('followerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // 获取粉丝数量
  Future<int> getFollowersCount(String userId) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('followingId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    
    // 处理可能的 null 值
    return snapshot.count ?? 0;
  }

  // 获取关注数量
  Future<int> getFollowingCount(String userId) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('followerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    
    // 处理可能的 null 值
    return snapshot.count ?? 0;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> followUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User is not logged in');

    final batch = _firestore.batch();
    
    final friendshipRef = _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId');
    
    batch.set(friendshipRef, {
      'followerId': currentUser.uid,
      'followingId': targetUserId,
      'createdAt': Timestamp.now(),
      'status': 'active',
    });

    batch.update(_firestore.collection('users').doc(currentUser.uid), {
      'followingCount': FieldValue.increment(1),
    });
    
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User is not logged in');

    final batch = _firestore.batch();
    
    final friendshipRef = _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId');
    
    batch.delete(friendshipRef);

    batch.update(_firestore.collection('users').doc(currentUser.uid), {
      'followingCount': FieldValue.increment(-1),
    });
    
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  Future<bool> isFollowing(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final friendshipDoc = await _firestore
        .collection('friendships')
        .doc('${currentUser.uid}_$targetUserId')
        .get();

    return friendshipDoc.exists;
  }

  Stream<QuerySnapshot> getFollowers(String userId) {
    return _firestore
        .collection('friendships')
        .where('followingId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Stream<QuerySnapshot> getFollowing(String userId) {
    return _firestore
        .collection('friendships')
        .where('followerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Future<int> getFollowersCount(String userId) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('followingId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }

  Future<int> getFollowingCount(String userId) async {
    final snapshot = await _firestore
        .collection('friendships')
        .where('followerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }
}
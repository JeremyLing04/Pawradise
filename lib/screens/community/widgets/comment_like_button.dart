// lib/screens/community/widgets/comment_like_button.dart
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentLikeButton extends StatefulWidget {
  final String commentId;
  final int initialLikes;

  const CommentLikeButton({
    super.key,
    required this.commentId,
    required this.initialLikes,
  });

  @override
  State<CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<CommentLikeButton> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late int _currentLikes;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.initialLikes;
    _isLiked = false;
  }

  Future<bool> _checkIfLiked() async {
    if (_currentUser == null) return false;

    final doc = await _firestore
        .collection('comment_likes')
        .where('commentId', isEqualTo: widget.commentId)
        .where('userId', isEqualTo: _currentUser!.uid)
        .get();

    return doc.docs.isNotEmpty;
  }

  Future<bool> _onLikeButtonTapped(bool isLiked) async {
    if (_currentUser == null) return false;

    try {
      final likeQuery = _firestore
          .collection('comment_likes')
          .where('commentId', isEqualTo: widget.commentId)
          .where('userId', isEqualTo: _currentUser!.uid);

      final likeDocs = await likeQuery.get();

      if (isLiked) {
        // 取消点赞
        if (likeDocs.docs.isNotEmpty) {
          await _firestore.runTransaction((transaction) async {
            transaction.delete(likeDocs.docs.first.reference);
            transaction.update(
              _firestore.collection('comments').doc(widget.commentId),
              {'likes': FieldValue.increment(-1)},
            );
          });
        }
        setState(() {
          _currentLikes--;
          _isLiked = false;
        });
        return false;
      } else {
        // 点赞
        await _firestore.runTransaction((transaction) async {
          final newLikeRef = _firestore.collection('comment_likes').doc();
          transaction.set(newLikeRef, {
            'id': newLikeRef.id,
            'commentId': widget.commentId,
            'userId': _currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(
            _firestore.collection('comments').doc(widget.commentId),
            {'likes': FieldValue.increment(1)},
          );
        });
        setState(() {
          _currentLikes++;
          _isLiked = true;
        });
        return true;
      }
    } catch (e) {
      print('Comment like action failed: $e');
      return isLiked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfLiked(),
      builder: (context, snapshot) {
        final bool isCurrentlyLiked = snapshot.hasData ? snapshot.data! : _isLiked;

        return LikeButton(
          size: 16,
          isLiked: isCurrentlyLiked,
          likeBuilder: (bool isLiked) {
            return Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: isLiked ? Colors.green : Colors.grey,
              size: 16,
            );
          },
          countBuilder: (int? count, bool isLiked, String text) {
            return Text(
              text,
              style: TextStyle(
                color: isLiked ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            );
          },
          onTap: _onLikeButtonTapped,
        );
      },
    );
  }
}
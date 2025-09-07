import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButtonWidget extends StatefulWidget{
  final String postId;
  final int initialLikes;

  const LikeButtonWidget({
    super.key,
    required this.postId,
    required this.initialLikes,
  });

  @override
  State<LikeButtonWidget> createState()=>_LikedButtonWidgetState();
}

class _LikedButtonWidgetState extends State<LikeButtonWidget>{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late int _currentLikes;
  late bool _isLiked;

  @override
  void initState(){
    super.initState();
    _currentLikes=widget.initialLikes;
    _isLiked=false;
  }

  Future<bool> _checkIfLiked() async {
    if(_currentUser == null) return false;

    final doc = await _firestore
    .collection('post_likes')
    .where('postId', isEqualTo: widget.postId)
    .where('userId', isEqualTo: _currentUser!.uid)
    .get();

    return doc.docs.isNotEmpty;
  }

  Future<bool> _onLikedButtonTapped(bool isLiked) async{
    if(_currentUser == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return false;
    }

    try{
      final likeQuery = _firestore
      .collection('post_likes')
      .where('postId', isEqualTo: widget.postId)
      .where('userId', isEqualTo: _currentUser!.uid);

      final likeDocs = await likeQuery.get();

      if(isLiked){
        if(likeDocs.docs.isNotEmpty){
          await _firestore.runTransaction((transaction) async {
            transaction.delete(likeDocs.docs.first.reference);

            transaction.update(
              _firestore.collection('posts').doc(widget.postId), 
              {'likes': FieldValue.increment(-1)}
            );
          });
        }
        setState(() {
          _currentLikes--;
          _isLiked=false;
        });
        return false;
      }else{
        await _firestore.runTransaction((transaction) async {
          final newLikeRef = _firestore.collection('post_likes').doc();
          transaction.set(newLikeRef, {
            'id': newLikeRef.id,
            'postId': widget.postId,
            'userId': _currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(
            _firestore.collection('posts').doc(widget.postId), 
            {'likes': FieldValue.increment(1)}
          );
        });
        setState(() {
          _currentLikes++;
          _isLiked=true;
        });
        return true;
      }
    } catch (e) {
      print('Like action failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: $e')),
      );
      return isLiked;
    }
  }

  @override
  Widget build(BuildContext context){
    return FutureBuilder<bool>(
      future: _checkIfLiked(), 
      builder: (contextm, snapshot){
        final bool isCurrentlyLiked = snapshot.hasData ? snapshot.data! : _isLiked;

        return LikeButton(
          size: 28,
          isLiked: isCurrentlyLiked,
          likeBuilder: (bool isLiked){
            return Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.grey,
              size: 28,
            );
          },
          countBuilder: (int? count, bool isLiked, String text){
            final Color color=isLiked ? Colors.red : Colors.grey;
            return Text(
              text,
              style: TextStyle(color: color, fontSize: 14),
            );
          },
          onTap: _onLikedButtonTapped,
        );
      }
    );
  }
}
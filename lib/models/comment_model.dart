import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String? id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final Timestamp createdAt;
  final int likes;

  CommentModel({
    this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });

  factory CommentModel.fromFireStore(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '', 
      authorId: data['authorId'] ?? '', 
      authorName: data['authorName'] ?? '', 
      content: data['content'], 
      createdAt: data['createdAt'],
      likes: (data['likes'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,
      'likes': likes,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    Timestamp? createdAt,
    int? likes,
  }){
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId, 
      authorId: authorId ?? this.authorId, 
      authorName: authorName ?? this.authorName, 
      content: content ?? this.content, 
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }

  @override
  String toString(){
    return 'CommentModel(id: $id, author: $authorName, content: ${content.length > 20 ? content.substring(0, 20) + "..." : content})';
  }
}
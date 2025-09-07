import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String type;
  final int likes;
  final int comments;
  final bool isResolved;
  final Timestamp createdAt;
  final bool hasImage;
  final String imageUrl;

  PostModel({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.type,
    this.likes = 0,
    this.comments = 0,
    this.isResolved = false,
    required this.createdAt,
    this.hasImage = false,
    this.imageUrl = '',
  });

  factory PostModel.fromFireStore(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'discussion',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      isResolved: data['isResolved'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      hasImage: data['hasImage'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'type': type,
      'likes': likes,
      'comments': comments,
      'isResolved': isResolved,
      'createdAt': createdAt,
      'hasImage': hasImage,
      'imageUrl': imageUrl,
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    String? type,
    int? likes,
    int? comments,
    bool? isResolved,
    Timestamp? createdAt,
    bool? hasImage,
    String? imageUrl,
  }){
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      hasImage: hasImage ?? this.hasImage,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString(){
    return 'PostModel(id: $id, title, $title, type: $type)';
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawradise/models/location_model.dart';

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
  final List<String> keywords; // 新增关键词字段

  // 新增事件相关字段
  final DateTime? eventTime;
  final String? eventDescription;
  final String? eventType;

  // 新增位置字段
  final Map<String, dynamic>? location;

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
    required this.keywords, // 新增
    this.eventTime,
    this.eventDescription,
    this.eventType,
    this.location, // 新增位置参数
  });

  factory PostModel.fromFireStore(DocumentSnapshot doc) {
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
      keywords: List<String>.from(data['keywords'] ?? []), // 新增
      eventTime: data['eventTime'] != null ? (data['eventTime'] as Timestamp).toDate() : null,
      eventDescription: data['eventDescription'] ?? '',
      eventType: data['eventType'] ?? 'other',
      location: data['location'] != null ? Map<String, dynamic>.from(data['location']) : null, // 新增
    );
  }

  // 从 Map 创建 PostModel（备用方法）
  factory PostModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'discussion',
      likes: (map['likes'] ?? 0).toInt(),
      comments: (map['comments'] ?? 0).toInt(),
      isResolved: map['isResolved'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      hasImage: map['hasImage'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? []), // 新增
    );
  }

  Map<String, dynamic> toMap() {
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
      'keywords': keywords, // 新增
      'eventTime': eventTime != null ? Timestamp.fromDate(eventTime!) : null,
      'eventDescription': eventDescription,
      'eventType': eventType,
      'location': location, // 新增
    };
  }

  // 添加位置转换方法
  static Map<String, dynamic>? locationFromModel(LocationModel? locationModel) {
    if (locationModel == null) return null;
    
    return {
      'id': locationModel.id,
      'name': locationModel.name,
      'description': locationModel.description,
      'latitude': locationModel.latitude,
      'longitude': locationModel.longitude,
      'rating': locationModel.rating,
      'category': locationModel.category,
    };
  }

  // 静态方法：生成搜索关键词
  static List<String> generateKeywords(String title, String content) {
    if (title.isEmpty && content.isEmpty) return [];
    
    String combinedText = '$title $content'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fa5]'), '') // 保留字母、数字、空格和中文
        .replaceAll(RegExp(r'\s+'), ' ');
    
    List<String> words = combinedText.split(' ');
    Set<String> keywords = {};
    
    // 添加整个短语
    if (combinedText.length > 2) {
      keywords.add(combinedText);
    }
    
    // 添加所有单词
    for (String word in words) {
      if (word.length > 1) {
        keywords.add(word);
      }
    }
    
    // 添加所有可能的前缀（用于自动补全）
    for (String word in words) {
      for (int i = 1; i <= word.length; i++) {
        String prefix = word.substring(0, i);
        if (prefix.length > 1) {
          keywords.add(prefix);
        }
      }
    }
    
    return keywords.toList();
  }

  // 创建新帖子时的便捷方法，自动生成关键词
  factory PostModel.createNew({
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    required String type,
    bool hasImage = false,
    String imageUrl = '',
    DateTime? eventTime,
    String? eventDescription,
    String? eventType,
  }) {
    return PostModel(
      authorId: authorId,
      authorName: authorName,
      title: title,
      content: content,
      type: type,
      createdAt: Timestamp.now(),
      hasImage: hasImage,
      imageUrl: imageUrl,
      keywords: generateKeywords(title, content), // 自动生成关键词
      eventTime: eventTime,
      eventDescription: eventDescription,
      eventType: eventType,
    );
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
    List<String>? keywords, // 新增
  }) {
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
      keywords: keywords ?? this.keywords, // 新增
      eventTime: eventTime ?? this.eventTime,
      eventDescription: eventDescription ?? this.eventDescription,
      eventType: eventType ?? this.eventType,
    );
  }

  @override
  String toString() {
    return 'PostModel(id: $id, title: $title, type: $type, keywords: $keywords)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
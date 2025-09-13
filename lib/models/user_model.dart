import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String username;
  final int karmaPoints;
  final DateTime createdAt;
  final List<String> searchKeywords; // 搜索关键词字段

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.karmaPoints,
    required this.createdAt,
    required this.searchKeywords,
  });

  // ✅ 从Firestore文档转成User对象
  factory User.fromFirestore(Map<String, dynamic> doc, String id) {
    return User(
      id: id,
      email: doc['email'] ?? '',
      username: doc['username'] ?? '',
      karmaPoints: doc['karmaPoints'] ?? 0,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      searchKeywords: List<String>.from(doc['searchKeywords'] ?? []),
    );
  }

  // ✅ 将User对象转为Map，用于写入Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'karmaPoints': karmaPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'searchKeywords': searchKeywords,
    };
  }

  // 静态方法：生成用户搜索关键词（只基于用户名）
  static List<String> generateSearchKeywords(String username) {
    Set<String> keywords = {};
    
    String cleanedUsername = username.toLowerCase().trim();
    
    if (cleanedUsername.isEmpty) return [];
    
    // 添加完整用户名
    keywords.add(cleanedUsername);
    
    // 生成用户名的所有前缀
    for (int i = 1; i <= cleanedUsername.length; i++) {
      String prefix = cleanedUsername.substring(0, i);
      if (prefix.length > 1) {
        keywords.add(prefix);
      }
    }
    
    // 添加用户名中的每个字（针对中文用户名）
    for (int i = 0; i < cleanedUsername.length; i++) {
      String character = cleanedUsername[i];
      // 如果是中文字符或长度大于1的字符
      if (character.length == 1 && character.codeUnitAt(0) > 255) {
        keywords.add(character);
      }
    }
    
    return keywords.toList();
  }

  // 创建新用户时的便捷方法，自动生成搜索关键词
  factory User.createNew({
    required String id,
    required String email,
    required String username,
    int karmaPoints = 0,
  }) {
    return User(
      id: id,
      email: email,
      username: username,
      karmaPoints: karmaPoints,
      createdAt: DateTime.now(),
      searchKeywords: generateSearchKeywords(username), // 只基于用户名生成关键词
    );
  }

  // 更新用户信息时的便捷方法
  User copyWith({
    String? email,
    String? username,
    int? karmaPoints,
    List<String>? searchKeywords,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      createdAt: createdAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  // 当用户名更新时重新生成搜索关键词
  User withUpdatedSearchKeywords() {
    return copyWith(
      searchKeywords: generateSearchKeywords(username),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}
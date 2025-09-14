
// user.dart
import 'package:cloud_firestore/cloud_firestore.dart'; 

class User {
  final String id;
  final String email;
  final String username;
  final int karmaPoints;
  final DateTime createdAt;
  final String? avatarUrl; // 添加头像URL字段
  final String bio; // 添加bio字段
  final List<String> searchKeywords; // 搜索关键词字段

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.karmaPoints,
    required this.createdAt,
    this.avatarUrl, // 头像URL，可为空
    this.bio = '', // bio，默认为空字符串
    required this.searchKeywords,
  });

  // ✅ 从Firestore文档转成User对象
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      karmaPoints: data['karmaPoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'], // 从Firestore读取头像URL
      bio: data['bio'] ?? '', // 从Firestore读取bio
      searchKeywords: data['searchKeywords'] ?? [],
    );
  }

  // ✅ 从Map数据创建User对象（用于其他数据源）
  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      karmaPoints: data['karmaPoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'],
      bio: data['bio'] ?? '',
      searchKeywords: data['searchKeywords'] ?? [],
    );
  }

  // ✅ 将User对象转为Map，用于写入Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'karmaPoints': karmaPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatarUrl': avatarUrl, // 添加头像URL到Map
      'bio': bio, // 添加bio到Map
      'updatedAt': FieldValue.serverTimestamp(), // 添加更新时间
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
    String? avatarUrl,
    String? bio,
    List<String>? searchKeywords,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      createdAt: createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

    // 当用户名更新时重新生成搜索关键词
  User withUpdatedSearchKeywords() {
    return copyWith(
      searchKeywords: generateSearchKeywords(username),
    );
  }

  // ✅ 获取默认头像（当avatarUrl为空时使用）
  String get displayAvatarUrl {
    return avatarUrl ?? 'https://via.placeholder.com/150/cccccc/ffffff?text=${username[0]}';
  }

  // ✅ 重写toString方法，便于调试
  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, karmaPoints: $karmaPoints, bio: $bio}';
  }

  // ✅ 重写equals和hashCode方法
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
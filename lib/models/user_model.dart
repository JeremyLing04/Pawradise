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

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.karmaPoints,
    required this.createdAt,
    this.avatarUrl, // 头像URL，可为空
    this.bio = '', // bio，默认为空字符串
  });

  // // 🚀 关键：创建一个模拟用户的工厂方法/静态方法
  // factory User.mock() {
  //   return User(
  //     id: 'mock_user_id_123456',
  //     email: 'shenghan@example.com',
  //     username: 'ShengHan',
  //     karmaPoints: 42,
  //     createdAt: DateTime.now().subtract(Duration(days: 30)),
  //     avatarUrl: 'https://example.com/avatar.jpg', // 模拟头像
  //     bio: '热爱宠物，养了两只猫和一只狗 🐱🐶', // 模拟bio
  //   );
  // }

  // // 🚀 可选：如果你需要一个模拟用户列表
  // static List<User> mockUsers() {
  //   return [
  //     User.mock(),
  //     User(
  //       id: 'mock_user_id_789',
  //       email: 'vicky@example.com',
  //       username: 'VickyYii',
  //       karmaPoints: 100,
  //       createdAt: DateTime.now().subtract(Duration(days: 15)),
  //       avatarUrl: 'https://example.com/vicky_avatar.jpg',
  //       bio: '宠物摄影师，擅长捕捉宠物的可爱瞬间 📸',
  //     ),
  //   ];
  // }

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
    };
  }

  // ✅ 复制方法，用于更新部分字段
  User copyWith({
    String? email,
    String? username,
    int? karmaPoints,
    String? avatarUrl,
    String? bio,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      createdAt: createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
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
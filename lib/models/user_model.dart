// user.dart
import 'package:cloud_firestore/cloud_firestore.dart'; 
class User {
  final String id;
  final String email;
  final String username;
  final int karmaPoints;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.karmaPoints,
    required this.createdAt,
  });

  // // 🚀 关键：创建一个模拟用户的工厂方法/静态方法
  // // 这样我们可以用 User.mock() 快速得到一个模拟用户对象
  // factory User.mock() {
  //   return User(
  //     id: 'mock_user_id_123456',
  //     email: 'shenghan@example.com',
  //     username: 'ShengHan',
  //     karmaPoints: 42,
  //     createdAt: DateTime.now().subtract(Duration(days: 30)), // 假设30天前创建
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
  //     ),
  //   ];
  // }

  // ✅ 为之后连接Firebase准备的方法：从Firestore文档转成User对象
  factory User.fromFirestore(Map<String, dynamic> doc, String id) {
    return User(
      id: id,
      email: doc['email'] ?? '',
      username: doc['username'] ?? '',
      karmaPoints: doc['karmaPoints'] ?? 0,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
    );
  }

  // ✅ 为之后连接Firebase准备的方法：将User对象转为Map，用于写入Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'karmaPoints': karmaPoints,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
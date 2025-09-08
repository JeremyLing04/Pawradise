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
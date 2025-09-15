// models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? response; 

  ChatMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.response,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp,
      'response': response,
    };
  }

  static ChatMessage fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      isUser: data['isUser'] ?? true,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      response: data['response'],
    );
  }
}
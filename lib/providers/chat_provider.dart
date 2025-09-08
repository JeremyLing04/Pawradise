// providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
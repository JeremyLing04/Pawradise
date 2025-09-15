// screens/chat/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Scroll to the bottom after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // Scroll chat to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Send user message to AI service
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      await _aiService.sendMessage(message);
    } catch (e) {
      // Show error if sending fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending failed: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Clear entire chat history
  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat History'),
        content: Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _aiService.clearChatHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 24),
            SizedBox(width: 8),
            Text(
              'Ask PawPal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.accent),
            onPressed: _clearChat,
            tooltip: 'Clear chat history',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header showing welcome text
          _buildWelcomeHeader(),
          // Chat messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _aiService.getChatHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load chat history'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                final messages = snapshot.data ?? [];
                
                // Scroll to bottom whenever new messages appear
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          // Input field for user messages
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Build the welcome header
  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ask me anything about dogs! Training, health, diet, behavior advice, and more',
            style: TextStyle(fontSize: 14, color: AppColors.accent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build a single chat message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AI avatar
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message container
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: message.isUser 
                      ? Text(message.message, style: TextStyle(color: Colors.white, fontSize: 14))
                      : Markdown(
                          data: message.response ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                            strong: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                            em: TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                            listBullet: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                            blockquote: TextStyle(color: Colors.grey[700], fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                          ),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                        ),
                ),
                SizedBox(height: 4),
                // Timestamp
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            // User avatar
            CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  // Build the input field for typing messages
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask a question about dogs...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          _isLoading
              ? CircularProgressIndicator(color: AppColors.accent)
              : IconButton(icon: Icon(Icons.send, color: AppColors.primary), onPressed: _sendMessage),
        ],
      ),
    );
  }

  // Format timestamp as HH:mm
  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

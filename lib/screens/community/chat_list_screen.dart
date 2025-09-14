import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/chat_service.dart';
import 'package:pawradise/models/chat_model.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // 实现搜索功能
              },
            ),
          ),
          
          // 聊天列表
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with someone!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final chatRoom = ChatRoom.fromFirestore(doc);
                    return _buildChatListItem(chatRoom);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startNewChat(context);
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
    );
  }

  // 开始新聊天的方法
  void _startNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewChatScreen(),
      ),
    );
  }

  Widget _buildChatListItem(ChatRoom chatRoom) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const SizedBox();

    final otherUserId = chatRoom.getOtherUserId(currentUser.uid);
    final otherUserName = chatRoom.getOtherUserName(currentUser.uid);
    final isUnread = chatRoom.hasUnreadMessages(currentUser.uid);

    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(chatRoom, otherUserName);
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green,
          child: Text(
            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          otherUserName,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          chatRoom.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            color: isUnread ? Colors.green : Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chatRoom.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chatRoom.unreadCount > 9 ? '9+' : chatRoom.unreadCount.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: chatRoom.id,
                otherUserName: otherUserName,
                otherUserId: otherUserId,
              ),
            ),
          ).then((_) {
            _chatService.markAsRead(chatRoom.id);
          });
        },
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteDialog(ChatRoom chatRoom, String otherUserName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: Text(
            'Are you sure you want to delete the conversation with $otherUserName? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteChatRoom(chatRoom);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 删除聊天室
  Future<void> _deleteChatRoom(ChatRoom chatRoom) async {
    try {
      await _chatService.deleteChatRoom(chatRoom.id);
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    return '${date.month}/${date.day}';
  }
}
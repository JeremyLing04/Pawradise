import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/chat_service.dart';
import 'package:pawradise/services/friends_service.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final FriendsService _friendService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
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
                hintText: 'Search following users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _friendService.getFollowing(currentUser?.uid ?? ''),
              builder: (context, followingSnapshot) {
                if (followingSnapshot.hasError) {
                  return Center(child: Text('Error: ${followingSnapshot.error}'));
                }

                if (followingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!followingSnapshot.hasData || followingSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No following users yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Follow someone to start a chat!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // 获取所有关注用户的ID
                final followingIds = followingSnapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['followingId'] as String;
                }).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: followingIds)
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.hasError) {
                      return Center(child: Text('Error: ${usersSnapshot.error}'));
                    }

                    if (usersSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No users found'),
                      );
                    }

                    final users = usersSnapshot.data!.docs.where((doc) {
                      final userData = doc.data() as Map<String, dynamic>;
                      final userName = userData['name'] ?? 'Unknown User';
                      final userEmail = userData['email'] ?? '';
                      
                      // 根据搜索查询过滤
                      if (_searchQuery.isNotEmpty) {
                        return userName.toLowerCase().contains(_searchQuery) ||
                               userEmail.toLowerCase().contains(_searchQuery);
                      }
                      
                      return true;
                    }).toList();

                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No following users'
                              : 'No users found for "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;
                        final userName = userData['name'] ?? 'Unknown User';
                        final userEmail = userData['email'] ?? '';
                        final userAvatar = userData['avatar'] ?? '';

                        return ListTile(
                          leading: userAvatar.isNotEmpty
                              ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(userAvatar),
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    userName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          title: Text(userName),
                          subtitle: Text(userEmail),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat, color: Colors.green),
                            onPressed: () => _startChatWithUser(userId, userName),
                          ),
                          onTap: () => _startChatWithUser(userId, userName),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      
      Navigator.pop(context); // 关闭选择用户页面
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }
}
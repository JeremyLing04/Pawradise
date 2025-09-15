import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/chat_service.dart';
import 'package:pawradise/services/friends_service.dart';
import 'chat_screen.dart';
import '../../constants.dart';

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
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // Search bar with rounded corners
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search following users...',
                  prefixIcon: Icon(Icons.search, color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.accent.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
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
                  return _buildEmptyState(
                    'No following users yet',
                    'Follow someone to start a chat!',
                    Icons.group_outlined,
                  );
                }

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
                      return _buildEmptyState(
                        'No users found',
                        '',
                        Icons.person_off,
                      );
                    }

                    final users = usersSnapshot.data!.docs.where((doc) {
                      final userData = doc.data() as Map<String, dynamic>;
                      final userName = userData['name'] ?? 'Unknown User';
                      final userEmail = userData['email'] ?? '';
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

                        return GestureDetector(
                          onTap: () => _startChatWithUser(userId, userName),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accent, width: 2),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              leading: userAvatar.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(userAvatar),
                                    )
                                  : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.accent,
                                      child: Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(userEmail),
                              trailing: Icon(Icons.chat, color: AppColors.accent),
                            ),
                          ),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      Navigator.pop(context); // close selection
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

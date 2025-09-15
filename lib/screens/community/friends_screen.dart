import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/friends_service.dart';
import 'package:pawradise/services/chat_service.dart';
import '../profile/profile_screen.dart';
import 'chat_screen.dart';
import '../../constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _locallyUnfollowed = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
        ),
        body: const Center(child: Text('Please log in first')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: AppColors.secondary,
              child: TabBar(
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.background,
                indicatorColor: AppColors.accent,
                tabs: [
                  Tab(text: 'Followers'),
                  Tab(text: 'Following'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFollowersList(currentUser.uid),
                  _buildFollowingList(currentUser.uid),
                  _buildRequestsList(currentUser.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendsService.getFollowers(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No followers yet',
            'People who follow you will appear here',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final followerId = data['followerId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(followerId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final username = userData['username'] ?? 'Unknown';
                final email = userData['email'] ?? '';

                return _buildUserTile(
                  userId: followerId,
                  username: username,
                  email: email,
                  isFollowingTab: false,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendsService.getFollowing(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'Not following anyone yet',
            'Follow users to see them here',
            Icons.person_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final followingId = data['followingId'];

            if (_locallyUnfollowed.containsKey(followingId)) {
              return _buildUnfollowedUserItem(followingId);
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(followingId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final username = userData['username'] ?? 'Unknown';
                final email = userData['email'] ?? '';

                return _buildUserTile(
                  userId: followingId,
                  username: username,
                  email: email,
                  isFollowingTab: true,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserTile({
    required String userId,
    required String username,
    required String email,
    required bool isFollowingTab,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: AppColors.accent),
          ),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message button
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _startChatWithUser(userId, username),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Icon(Icons.message, size: 20, color: AppColors.background),
                ),
              ),
              if (isFollowingTab) ...[
                const SizedBox(width: 8),
                // Unfollow button
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _friendsService.unfollowUser(userId);
                        setState(() {
                          _locallyUnfollowed[userId] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Unfollowed successfully'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                await _friendsService.followUser(userId);
                                setState(() {
                                  _locallyUnfollowed.remove(userId);
                                });
                              },
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Failed to unfollow: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: Icon(Icons.person_remove, size: 20, color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnfollowedUserItem(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox();
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: AppColors.accent),
            ),
            title: Text(username, style: const TextStyle(color: Colors.grey)),
            subtitle: const Text('Unfollowed', style: TextStyle(color: Colors.grey)),
            trailing: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _friendsService.followUser(userId);
                    setState(() {
                      _locallyUnfollowed.remove(userId);
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Failed to follow back: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
                child: Text('Follow Back', style: TextStyle(color: AppColors.accent)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(String userId) {
    return _buildEmptyState(
      'No friend requests',
      'Friend request system can be implemented later',
      Icons.person_add_disabled,
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
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    }
  }
}

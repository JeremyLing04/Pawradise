import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/friends_service.dart';
import 'package:pawradise/services/chat_service.dart'; // 添加 ChatService
import 'profile_screen.dart';
import 'chat_screen.dart'; // 导入 ChatScreen

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService(); // 添加 ChatService
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, bool> _locallyUnfollowed = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: 'Followers'),
                Tab(text: 'Following'),
                Tab(text: 'Requests'),
              ],
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No followers yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
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
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(followerId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(),
                    title: Text('Loading...'),
                  );
                }

                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('User not found'),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final username = userData['username'] ?? 'Unknown User';
                final email = userData['email'] ?? '';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {
                        _startChatWithUser(followerId, username);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(color: Colors.green.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.message, size: 18, color: Colors.green),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: followerId),
                      ),
                    );
                  },
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

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Not following anyone yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final followingId = data['followingId'];

            // 检查是否在本地已取消关注
            if (_locallyUnfollowed.containsKey(followingId)) {
              return _buildUnfollowedUserItem(followingId);
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(followingId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(),
                    title: Text('Loading...'),
                  );
                }

                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('User not found'),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final username = userData['username'] ?? 'Unknown User';
                final email = userData['email'] ?? '';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Message button
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {
                            _startChatWithUser(followingId, username);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(color: Colors.green.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.message, size: 18, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unfollow button
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await _friendsService.unfollowUser(followingId);
                              setState(() {
                                _locallyUnfollowed[followingId] = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Unfollowed successfully'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () async {
                                      try {
                                        await _friendsService.followUser(followingId);
                                        setState(() {
                                          _locallyUnfollowed.remove(followingId);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Followed back successfully')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to follow back: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to unfollow: $e')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.person_remove, size: 18, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: followingId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // 新增：开始与用户聊天的方法
  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 获取或创建聊天室
      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      
      // 导航到聊天界面
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

  Widget _buildUnfollowedUserItem(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Unknown User';

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            username,
            style: const TextStyle(color: Colors.grey),
          ),
          subtitle: const Text(
            'Unfollowed',
            style: TextStyle(color: Colors.grey),
          ),
          trailing: SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _friendsService.followUser(userId);
                  setState(() {
                    _locallyUnfollowed.remove(userId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Followed back successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to follow back: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Follow Back'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(String userId) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_disabled, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No friend requests feature yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Friend request system can be implemented later',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
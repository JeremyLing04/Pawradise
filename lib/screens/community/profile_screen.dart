import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/services/friends_service.dart';
import '../../models/user_model.dart' as app_model;
import '../../models/post_model.dart';
import 'widgets/post_card.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FriendsService _friendsService = FriendsService();
  int _postsCount = 0;
  int _followingCount = 0;
  int _followersCount = 0;
  
  bool _isFollowing = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _checkIfCurrentUser();
    _loadStats();
    _checkFollowStatus();
  }

  void _checkIfCurrentUser() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _isCurrentUser = currentUser.uid == widget.userId;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final postsSnapshot = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .count()
        .get();

      final followingCount = await _friendsService.getFollowingCount(widget.userId);
      final followersCount = await _friendsService.getFollowersCount(widget.userId);

      if (mounted) {
        setState(() {
          _postsCount = postsSnapshot.count ?? 0; // 处理可能的 null 值
          _followingCount = followingCount;
          _followersCount = followersCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && !_isCurrentUser) {
      try {
        final isFollowing = await _friendsService.isFollowing(widget.userId);
        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
          });
        }
      } catch (e) {
        debugPrint('Error checking follow status: $e');
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isCurrentUser) return;

    try {
      if (_isFollowing) {
        await _friendsService.unfollowUser(widget.userId);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount--;
          });
        }
      } else {
        await _friendsService.followUser(widget.userId);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e')),
        );
      }
    }
  }

  Stream<app_model.User> _getUserData() {
    return _firestore
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return app_model.User.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return app_model.User(
        id: widget.userId,
        email: 'unknown@email.com',
        username: 'Unknown User',
        karmaPoints: 0,
        createdAt: DateTime.now(),
        searchKeywords: [],
      );
    });
  }

  Stream<QuerySnapshot> _getUserPosts() {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<app_model.User>(
          stream: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!.username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return const Text('个人主页');
          },
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
        ],
      ),
      body: StreamBuilder<app_model.User>(
        stream: _getUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(child: Text('错误: ${userSnapshot.error}'));
          }

          final user = userSnapshot.data!;

          return Column(
            children: [
              // 用户信息卡片
              _buildUserInfoCard(user),
              
              // 分割线
              const Divider(height: 1, thickness: 1),
              
              // 帖子列表标题
              _buildPostsHeader(),
              
              // 帖子列表
              Expanded(
                child: _buildUserPosts(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(app_model.User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 统计信息
              Expanded(
                child: _buildCompactStats(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 积分信息
          _buildKarmaInfo(user),
          
          const SizedBox(height: 16),
          
          // 操作按钮（如果不是当前用户）
          if (!_isCurrentUser) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '统计信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('帖子', _postsCount),
            _buildStatItem('追踪', _followingCount),
            _buildStatItem('粉丝', _followersCount),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }

    Widget _buildKarmaInfo(app_model.User user) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 20, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              '${user.karmaPoints} 积分',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.amber[800],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '加入于 ${_formatDate(user.createdAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildActionButtons() {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[200] : Colors.green,
                  foregroundColor: _isFollowing ? Colors.grey[700] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFollowing ? Icons.check : Icons.person_add,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFollowing ? 'Follwing' : 'Follow',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, size: 18, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildPostsHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey[50],
        child: Row(
          children: [
            const Icon(Icons.post_add, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _isCurrentUser ? '我的帖子' : '用户帖子',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildUserPosts() {
      return StreamBuilder<QuerySnapshot>(
        stream: _getUserPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _isCurrentUser ? '你还没有发布过帖子' : '该用户还没有发布过帖子',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
              final post = PostModel.fromFireStore(doc);
              
              return Column(
                children: [
                  PostCard(
                    post: post,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: doc.id),
                      ),
                    ),
                  ),
                  if (index < snapshot.data!.docs.length - 1)
                    const Divider(height: 24, thickness: 1),
                ],
              );
            },
          );
        },
      );
    }

    String _formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
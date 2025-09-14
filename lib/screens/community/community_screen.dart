import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/screens/community/search_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';
import '../../models/post_model.dart';
import 'friends_screen.dart';
import 'chat_list_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'discussion', 'alert', 'event'];
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // 获取探索页面的帖子流
  Stream<QuerySnapshot> get _filteredPosts {
    final query = _selectedFilter == 'all'
        ? FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
            .collection('posts')
            .where('type', isEqualTo: _selectedFilter)
            .orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  // 构建关注页面
  Widget _buildFollowingPosts() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to see followed posts'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendships')
          .where('followerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active') // 改为 'active' 与 FriendsService 一致
          .snapshots(),
      builder: (context, friendshipsSnapshot) {
        if (friendshipsSnapshot.hasError) {
          print('Friendships error: ${friendshipsSnapshot.error}');
          return Center(child: Text('Error: ${friendshipsSnapshot.error}'));
        }

        if (friendshipsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!friendshipsSnapshot.hasData || friendshipsSnapshot.data!.docs.isEmpty) {
          return _buildEmptyFollowingState();
        }

        final followingIds = friendshipsSnapshot.data!.docs
            .map((doc) => doc['followingId'] as String)
            .toList();

        print('Found ${followingIds.length} followed users: $followingIds');

        if (followingIds.isEmpty) {
          return _buildEmptyFollowingState();
        }

        // 使用优化后的查询方法
        return StreamBuilder<QuerySnapshot>(
          stream: _getFollowingPostsStream(followingIds),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.hasError) {
              print('Posts error: ${postsSnapshot.error}');
              return Center(child: Text('Error: ${postsSnapshot.error}'));
            }
            return _buildPostsListFromSnapshot(postsSnapshot, true);
          },
        );
      },
    );
  }

  // 获取关注用户的帖子流
  Stream<QuerySnapshot> _getFollowingPostsStream(List<String> followingIds) {
    if (followingIds.isEmpty) {
      // 返回空流
      return Stream<QuerySnapshot>.fromIterable([]);
    }

    // 限制 whereIn 的数量（Firestore 最多支持 10个）
    final limitedIds = followingIds.length > 10 
        ? followingIds.sublist(0, 10) 
        : followingIds;

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', whereIn: limitedIds)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  // 空关注状态
  Widget _buildEmptyFollowingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'You are not following anyone yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
            ),
            child: const Text('Find friends to follow'),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Posts';
      case 'discussion':
        return 'Discussions';
      case 'alert':
        return 'Alerts';
      case 'event':
        return 'Events';
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentTabIndex == 0
            ? const Text(
                'Community',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : const Text(
                'Following',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 导航标签
          _buildNavigationTabs(),
          
          // 快速过滤器按钮栏（只在探索页面显示）
          if (_currentTabIndex == 0) _buildQuickFilterBar(),
          
          // 帖子列表
          Expanded(
            child: _currentTabIndex == 0
                ? StreamBuilder<QuerySnapshot>(
                    stream: _filteredPosts,
                    builder: (context, snapshot) {
                      return _buildPostsListFromSnapshot(snapshot, false);
                    },
                  )
                : _buildFollowingPosts(),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              heroTag: UniqueKey(), // 添加唯一的heroTag
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              ),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // 从快照构建帖子列表
  Widget _buildPostsListFromSnapshot(AsyncSnapshot<QuerySnapshot> snapshot, bool isFollowingPage) {
    if (snapshot.hasError) {
      print('Posts list error: ${snapshot.error}');
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowingPage ? Icons.people_outline : _getFilterIcon(_selectedFilter),
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isFollowingPage
                  ? 'No posts from followed users'
                  : _selectedFilter == 'all'
                      ? 'No posts found. Be the first to post!'
                      : 'No ${_getFilterLabel(_selectedFilter).toLowerCase()} found',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
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
        
        return PostCard(
          post: post, 
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: doc.id),
            ),
          ),
        );
      },
    );
  }

  // 构建导航标签
  Widget _buildNavigationTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Explore', 0),
          ),
          Expanded(
            child: _buildTabButton('Following', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;
    return TextButton(
      onPressed: () => setState(() => _currentTabIndex = index),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.green : Colors.grey,
        backgroundColor: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // 快速过滤器按钮栏
  Widget _buildQuickFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? filter : 'all';
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.green.withOpacity(0.1),
                checkmarkColor: Colors.green,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: Icon(
                  _getFilterIcon(filter),
                  size: 18,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? Colors.green : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 显示搜索
  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search posts or users...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // 实现搜索功能
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // 获取过滤器图标
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'all':
        return Icons.all_inclusive;
      case 'discussion':
        return Icons.forum;
      case 'alert':
        return Icons.warning;
      case 'event':
        return Icons.event;
      default:
        return Icons.category;
    }
  }
}
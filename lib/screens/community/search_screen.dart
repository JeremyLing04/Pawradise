import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/post_card.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart' as app_model; // 添加别名
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'posts'; // 'posts' 或 'users'

  // 搜索帖子
  Stream<QuerySnapshot> _searchPosts(String query) {
    if (query.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .where('keywords', arrayContains: query.toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 搜索用户
  Stream<QuerySnapshot> _searchUsers(String query) {
    if (query.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .snapshots();
  }

  // 构建搜索建议
  Widget _buildSearchSuggestions() {
    final suggestions = ['Flutter', 'Dart', '宠物', '医疗', '活动', '讨论'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return GestureDetector(
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              suggestion,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '搜索帖子或用户...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // 分类筛选
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryButton('帖子', 'posts'),
                const SizedBox(width: 12),
                _buildCategoryButton('用户', 'users'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 搜索建议（当没有搜索时显示）
          if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '热门搜索',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchSuggestions(),
                ],
              ),
            ),

          // 搜索结果
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            Expanded(
              child: _selectedCategory == 'posts'
                  ? _buildPostsResults()
                  : _buildUsersResults(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedCategory = value;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildPostsResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchPosts(_searchQuery),
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
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '没有找到关于"$_searchQuery"的帖子',
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
      },
    );
  }

  Widget _buildUsersResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchUsers(_searchQuery),
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
                const Icon(Icons.person_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '没有找到关于"$_searchQuery"的用户',
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
            final user = app_model.User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id); // 使用别名
            
            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              title: Text(user.username),
              subtitle: Text(user.email),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
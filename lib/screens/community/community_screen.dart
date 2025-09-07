import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';
import '../../models/post_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'all'; // 'all', 'discussion', 'alert', 'event'
  final List<String> _filterOptions = [
    'all',
    'discussion',
    'alert',
    'event'
  ];

  // 获取过滤后的Stream
  Stream<QuerySnapshot> get _filteredPosts {
    if (_selectedFilter == 'all') {
      return FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: _selectedFilter)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // 获取过滤器显示的文本
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
        title: const Text(
          'Community Board',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // 标题居中
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        // 移除了actions中的PopupMenuButton
      ),
      body: Column(
        children: [
          // 快速过滤器按钮栏
          _buildQuickFilterBar(),
          
          // 帖子列表
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filteredPosts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFilterIcon(_selectedFilter),
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
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
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        ),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
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
                selectedColor: Colors.green.withOpacity(0.2),
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
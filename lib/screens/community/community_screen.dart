// screens/community/community_screen.dart
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
import '../../constants.dart';

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

  // Stream of posts filtered by type
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

  // Build posts from followed users
  Widget _buildFollowingPosts() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to see followed posts'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendships')
          .where('followerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
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

        if (followingIds.isEmpty) {
          return _buildEmptyFollowingState();
        }

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

  // Stream for followed users' posts
  Stream<QuerySnapshot> _getFollowingPostsStream(List<String> followingIds) {
    if (followingIds.isEmpty) return Stream<QuerySnapshot>.fromIterable([]);
    final limitedIds = followingIds.length > 10 ? followingIds.sublist(0, 10) : followingIds;

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', whereIn: limitedIds)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'all') query = query.where('type', isEqualTo: _selectedFilter);

    return query.snapshots();
  }

  // Empty state for following page
  Widget _buildEmptyFollowingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'You are not following anyone yet.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
      backgroundColor: AppColors.accent.withOpacity(0.5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(55),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: Text(
              _currentTabIndex == 0 ? 'Community' : 'Following',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
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
        ),
      ),
      body: Column(
        children: [
          _buildNavigationTabs(),
          if (_currentTabIndex == 0) _buildQuickFilterBar(),
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
              heroTag: UniqueKey(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              ),
              backgroundColor: AppColors.accent.withOpacity(0.7),
              shape: const CircleBorder(),
              child: Icon(
                Icons.add,
                color: AppColors.background,
              ),
            )
          : null,
    );
  }

  // Build posts list from Firestore snapshot
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
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isFollowingPage
                  ? 'No posts from followed users'
                  : _selectedFilter == 'all'
                      ? 'No posts found. Be the first to post!'
                      : 'No ${_getFilterLabel(_selectedFilter).toLowerCase()} found',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
          eventId: post.type == 'event' ? doc.id : null,
        );
      },
    );
  }

  // Build navigation tabs
  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary, 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Explore', 0)),
          Expanded(child: _buildTabButton('Following', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.7) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }


  // Quick filter bar
  Widget _buildQuickFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                backgroundColor: AppColors.secondary,
                selectedColor: AppColors.accent.withOpacity(0.8),
                checkmarkColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: Icon(
                  _getFilterIcon(filter),
                  size: 18,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary.withOpacity(0.3),
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

  // Get filter icon
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

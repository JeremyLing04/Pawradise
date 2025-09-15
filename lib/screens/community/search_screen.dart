import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart' as app_model;
import 'post_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../../constants.dart';
import 'widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'posts';

  Stream<QuerySnapshot> _searchPosts(String query) {
    if (query.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('posts')
        .where('keywords', arrayContains: query.toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _searchUsers(String query) {
    if (query.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .snapshots();
  }

  Widget _buildSearchSuggestions() {
    final suggestions = ['Flutter', 'Dart', 'Pets', 'Medical', 'Events', 'Discussion'];
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
              color: AppColors.accent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              suggestion,
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _performSearch(String query) {
    setState(() => _searchQuery = query);
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
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              title: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),

          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search posts or users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                    : null,
                filled: true,
                fillColor: AppColors.primary.withOpacity(0.7),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide:  BorderSide(color: AppColors.accent, width: 2)),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // Category buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryButton('Posts', 'posts'),
                const SizedBox(width: 12),
                _buildCategoryButton('Users', 'users'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search suggestions or results
          Expanded(
            child: _searchQuery.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Popular Searches',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildSearchSuggestions(),
                      ],
                    ),
                  )
                : _selectedCategory == 'posts'
                    ? _buildPostsResults()
                    : _buildUsersResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedCategory = value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.accent.withOpacity(0.2) :  AppColors.secondary.withOpacity(0.7),
          foregroundColor: isSelected ? AppColors.background : AppColors.accent,
          side: BorderSide(color: AppColors.accent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPostsResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchPosts(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No posts found for "$_searchQuery"', Icons.search_off);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final post = PostModel.fromFireStore(doc);
            return PostCard(
              post: post,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: doc.id))),
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
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No users found for "$_searchQuery"', Icons.person_off);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final user = app_model.User.fromFirestore(doc);
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: user.id))),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey)),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

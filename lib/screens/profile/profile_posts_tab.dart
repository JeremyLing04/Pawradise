// screens/profile/profile_posts_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../screens/community/widgets/post_card.dart';
import '../../screens/community/post_detail_screen.dart';
import '../../constants.dart';

class ProfilePostsTab extends StatelessWidget {
  final String userId;

  const ProfilePostsTab({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts'));
        }
        
        final posts = snapshot.data?.docs ?? [];
        
        if (posts.isEmpty) {
          return Center(child: Text('No posts yet'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            try {
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
            } catch (e) {
              return ListTile(
                title: Text('Error loading post'),
                subtitle: Text('ID: ${doc.id}'),
              );
            }
          },
        );
      },
    );
  }
}
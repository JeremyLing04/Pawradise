// screens/profile/profile_posts_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../screens/community/widgets/post_card.dart';
import '../../screens/community/post_detail_screen.dart';
import '../../screens/community/edit_post_screen.dart'; // 添加导入
import '../../services/community_service.dart'; // 添加导入
import '../../constants.dart';

class ProfilePostsTab extends StatelessWidget {
  final String userId;
  final bool isCurrentUser; // 添加这个参数来判断是否是当前用户
  final Function(PostModel)? onEdit; // 添加编辑回调
  final Function(String)? onDelete; // 添加删除回调

  const ProfilePostsTab({
    super.key,
    required this.userId,
    this.isCurrentUser = false, // 默认为false
    this.onEdit,
    this.onDelete,
  });

  // 编辑帖子的方法
  void _editPost(BuildContext context, PostModel post) {
    if (onEdit != null) {
      onEdit!(post);
    } else {
      // 如果没有传递回调，直接导航到编辑页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPostScreen(post: post),
        ),
      );
    }
  }

  // 删除帖子的方法
  Future<void> _deletePost(BuildContext context, String postId) async {
    if (onDelete != null) {
      onDelete!(postId);
    } else {
      // 如果没有传递回调，直接执行删除
      final communityService = CommunityService();
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      
      if (postDoc.exists) {
        final post = PostModel.fromFireStore(postDoc);
        
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await communityService.deletePost(
              postId, 
              imageUrl: post.hasImage ? post.imageUrl : null
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post deleted successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete post: $e')),
            );
          }
        }
      }
    }
  }

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  isCurrentUser ? 'You haven\'t created any posts yet' : 'No posts yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (context, index) => Divider(
            color: AppColors.accent.withOpacity(0.4), 
            thickness: 2, 
            height: 24, 
          ),
          itemBuilder: (context, index) {
            final doc = posts[index];
            try {
              final post = PostModel.fromFireStore(doc);
              return PostCard(
                post: post,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: doc.id,
                      onEdit: isCurrentUser ? (postToEdit) => _editPost(context, postToEdit) : null,
                      onDelete: isCurrentUser ? (postId) => _deletePost(context, postId) : null,
                    ),
                  ),
                ),
                onEdit: isCurrentUser ? (postToEdit) => _editPost(context, postToEdit) : null,
                onDelete: isCurrentUser ? (postId) => _deletePost(context, postId) : null,
              );
            } catch (e) {
              return ListTile(
                title: const Text('Error loading post'),
                subtitle: Text('ID: ${doc.id}'),
              );
            }
          },
        );
      },
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pawradise/screens/community/widgets/like_button_widget.dart';
import '../../models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post does not exist.'));
          }

          // 使用 PostModel.fromFirestore 创建模型实例
          final post = PostModel.fromFireStore(snapshot.data!);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 图片部分（如果有图片）
                if (post.hasImage && post.imageUrl.isNotEmpty)
                  _buildDetailImage(post.imageUrl),
                
                // 内容部分
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 帖子类型徽章
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(post.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getTypeLabel(post.type),
                          style: TextStyle(
                            color: _getTypeColor(post.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 帖子标题
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 帖子内容
                      Text(
                        post.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 作者和时间信息
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green,
                            child: Text(
                              post.authorName[0],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatDetailTimestamp(post.createdAt),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 互动按钮
                      Row(
                        children: [
                          LikeButtonWidget(
                            postId: post.id!, // 使用从 Firestore 获取的帖子ID
                            initialLikes: post.likes,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.comment_outlined),
                            color: Colors.green,
                            iconSize: 28,
                          ),
                          Text(
                            '${post.comments}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          if (post.type == 'alert')
                            Chip(
                              label: Text(
                                post.isResolved ? 'Resolved' : 'Unresolved',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: post.isResolved ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建详情页图片
  Widget _buildDetailImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 300,
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image load failed', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    return {
      'alert': Colors.red,
      'discussion': Colors.blue,
      'event': Colors.green,
    }[type] ?? Colors.grey;
  }

  String _getTypeLabel(String type) {
    return {
      'alert': 'Alert',
      'discussion': 'Discussion',
      'event': 'Event',
    }[type] ?? type;
  }

  String _formatDetailTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
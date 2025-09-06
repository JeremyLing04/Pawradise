import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 帖子标题和类型
              Row(
                children: [
                  _buildPostTypeBadge(data['type']),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 帖子内容预览
              Text(
                data['content'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // 帖子和作者信息
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(data['authorName'][0]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['authorName'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(data['createdAt']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeBadge(String type) {
    final colors = {
      'alert': Colors.red,
      'discussion': Colors.blue,
      'event': Colors.green,
    };
    
    final labels = {
      'alert': '警报',
      'discussion': '讨论',
      'event': '活动',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[type]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[type] ?? type,
        style: TextStyle(
          color: colors[type],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
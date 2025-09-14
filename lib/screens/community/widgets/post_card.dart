import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:like_button/like_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/screens/community/widgets/like_button_widget.dart';
import 'package:pawradise/services/community_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final String? eventId;

  const PostCard({
    super.key, 
    required this.post, 
    required this.onTap,
    this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final CommunityService communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnPost = currentUserId == post.authorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.hasImage && post.imageUrl.isNotEmpty)
              _buildPostImage(post.imageUrl),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 帖子类型徽章
                  _buildPostTypeBadge(post.type),
                  const SizedBox(height: 8),

                  // 帖子标题
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 帖子内容预览
                  post.type == 'event'
                      ? MarkdownBody(
                          data: post.content,
                          softLineBreak: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, color: Colors.black87),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          shrinkWrap: true,
                        )
                      : Text(
                          post.content,
                          maxLines: post.hasImage ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                  
                  const SizedBox(height: 12),
                  
                  // 作者和时间信息
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green,
                        child: Text(
                          post.authorName[0],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.authorName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  
                  // 互动统计和活动按钮
                  const SizedBox(height: 16),
                  _buildBottomSection(context, communityService, currentUserId, isOwnPost),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部区域（点赞、评论、活动按钮）
  Widget _buildBottomSection(BuildContext context, CommunityService communityService, 
      String? currentUserId, bool isOwnPost) {
    return Row(
      children: [
        // 左侧：点赞和评论
        Expanded(
          child: Row(
            children: [
              LikeButtonWidget(
                postId: post.id!,
                initialLikes: post.likes,
              ),
              Text(
                '${post.likes}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post.comments}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        
        // 右侧：参加人数徽章和加入按钮（如果是事件类型）
        if (post.type == 'event' && eventId != null)
          Row(
            children: [
              // 所有事件帖子都显示参加人数徽章
              _buildParticipantBadge(context, communityService),
              
              // 只有不是自己的帖子才显示加入按钮
              if (!isOwnPost) 
                _buildEventJoinButton(context, communityService, currentUserId),
            ],
          ),
      ],
    );
  }

  // 构建参加人数徽章（所有事件帖子都显示）
  Widget _buildParticipantBadge(BuildContext context, CommunityService communityService) {
    return FutureBuilder<int>(
      future: communityService.getParticipantCount(eventId!),
      builder: (context, snapshot) {
        final participantCount = snapshot.data ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 16, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                '$participantCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建活动加入按钮（用于其他人的帖子）
  Widget _buildEventJoinButton(BuildContext context, CommunityService communityService, String? currentUserId) {
    return FutureBuilder<bool>(
      future: communityService.isUserJoined(eventId!),
      builder: (context, joinSnapshot) {
        final isJoined = joinSnapshot.data ?? false;
        
        return Container(
          margin: const EdgeInsets.only(left: 8),
          child: ElevatedButton(
            onPressed: () {
              communityService.joinEvent(post.id!, eventId!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isJoined ? 'Left ${post.title}' : 'Joined ${post.title}')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isJoined ? Colors.grey : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              isJoined ? 'Joined' : 'Join',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建帖子图片
  Widget _buildPostImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.grey),
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
      'alert': 'Alert',
      'discussion': 'Discussion',
      'event': 'Event',
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
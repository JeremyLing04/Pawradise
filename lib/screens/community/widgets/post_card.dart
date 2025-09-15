import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:like_button/like_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/screens/community/widgets/like_button_widget.dart';
import 'package:pawradise/services/community_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/post_model.dart';
import '../../../constants.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final String? eventId;
  final Function(PostModel)? onEdit;
  final Function(String)? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.eventId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final CommunityService communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnPost = currentUserId == post.authorId;

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      elevation: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (post.hasImage && post.imageUrl.isNotEmpty)
                _buildPostImage(post.imageUrl),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPostTypeBadge(post.type),
                        const Spacer(),
                        if (isOwnPost) _buildPostMenu(context),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    if (post.location != null && post.location!['name'] != null)
                      _buildLocationInfo(post.location!),
                    
                    const SizedBox(height: 8),
                    
                    post.type == 'event'
                        ? MarkdownBody(
                            data: post.content,
                            softLineBreak: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              strong: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            shrinkWrap: true,
                          )
                        : Text(
                            post.content,
                            maxLines: post.hasImage ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.accent,
                          child: Text(
                            post.authorName[0],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.authorName,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildBottomSection(context, communityService, currentUserId, isOwnPost),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call(post);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call(post.id!);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationInfo(Map<String, dynamic> location) {
    final locationName = location['name'] ?? '';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          locationName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context, CommunityService communityService, 
      String? currentUserId, bool isOwnPost) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              LikeButtonWidget(
                postId: post.id!,
                initialLikes: post.likes,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likes}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${post.comments}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        if (post.type == 'event' && eventId != null)
          Row(
            children: [
              _buildParticipantBadge(context, communityService),
              if (!isOwnPost)
                _buildEventJoinButton(context, communityService, currentUserId, post),
            ],
          ),
      ],
    );
  }

  Widget _buildParticipantBadge(BuildContext context, CommunityService communityService) {
    return FutureBuilder<int>(
      future: communityService.getParticipantCount(eventId!),
      builder: (context, snapshot) {
        final participantCount = snapshot.data ?? 0;
        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                '$participantCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventJoinButton(BuildContext context, CommunityService communityService, String? currentUserId, PostModel post) {
    return FutureBuilder<bool>(
      future: communityService.isUserJoined(eventId!),
      builder: (context, joinSnapshot) {
        final isJoined = joinSnapshot.data ?? false;
        return Container(
          margin: const EdgeInsets.only(left: 8),
          child: ElevatedButton(
            onPressed: () {
              communityService.joinEvent(
                post.id!, 
                eventId!, 
                context,
                eventTitle: post.title,
                eventTime: post.eventTime ?? DateTime.now().add(const Duration(hours: 1)),
                eventDescription: post.eventDescription ?? post.content,
                authorName: post.authorName,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isJoined ? 'Left ${post.title}' : 'Joined ${post.title}')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isJoined ? Colors.grey : AppColors.accent,
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

  Widget _buildPostImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
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
        color: colors[type]?.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[type] ?? AppColors.accent, width: 2),
      ),
      child: Text(
        labels[type] ?? type,
        style: TextStyle(
          color: colors[type] ?? AppColors.accent,
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
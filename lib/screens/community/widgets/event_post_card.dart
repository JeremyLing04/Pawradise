import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/post_model.dart';
import '../../../../models/event_model.dart';
import '../../../../services/community_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class EventPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final String? eventId;

  const EventPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final CommunityService communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 从标题中提取活动类型
    String getEventTypeFromTitle(String title) {
      if (title.contains('Vet Appointment')) return 'Vet';
      if (title.contains('Feeding')) return 'Feeding';
      if (title.contains('Walk')) return 'Walk';
      if (title.contains('Medication')) return 'Medication';
      if (title.contains('Grooming')) return 'Grooming';
      if (title.contains('Training')) return 'Training';
      if (title.contains('Other')) return 'Other';
      return 'Activity';
    }

    final eventType = getEventTypeFromTitle(post.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 事件类型徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$eventType Event',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  MarkdownBody(
                    data: post.content,
                    softLineBreak: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, color: Colors.black87),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    shrinkWrap: true,
                  ),

                  const SizedBox(height: 12),

                  // 参与按钮和计数
                  if (eventId != null)
                    FutureBuilder<List<String>>(
                      future: communityService.getEventParticipants(eventId!),
                      builder: (context, snapshot) {
                        final participants = snapshot.data ?? [];
                        final isJoined = participants.contains(currentUserId);
                        final participantCount = participants.length;

                        return Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (!isJoined) {
                                  communityService.joinEvent(
                                    post.id!,
                                    eventId!,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isJoined
                                    ? Colors.grey
                                    : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isJoined ? 'Joined' : 'Join Activity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$participantCount ${participantCount == 1 ? 'person' : 'people'} joined',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green,
                        child: Text(
                          post.authorName[0],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[300]),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined, size: 20),
                    onPressed: () {},
                    color: Colors.grey[600],
                  ),
                  Text(post.likes.toString()),

                  const SizedBox(width: 16),

                  IconButton(
                    icon: const Icon(Icons.comment_outlined, size: 20),
                    onPressed: () {},
                    color: Colors.grey[600],
                  ),
                  Text(post.comments.toString()),

                  const SizedBox(width: 16),

                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    onPressed: () {},
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
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

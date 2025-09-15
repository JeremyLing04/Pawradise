import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/screens/community/widgets/like_button_widget.dart';
import 'package:pawradise/screens/community/widgets/comment_like_button.dart';
import 'package:pawradise/services/community_service.dart';
import 'package:pawradise/services/friends_service.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../profile/profile_screen.dart'; // 导入 ProfileScreen
import '../../constants.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendsService _friendsService = FriendsService();
  bool _isLoadingComment = false;
  bool _isFollowingAuthor = false;
  bool _isCurrentUserPost = false;
  bool _showComments = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFollowStatus();
    });
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final postDoc = await _firestore.collection('posts').doc(widget.postId).get();
    if (!postDoc.exists) return;

    final post = PostModel.fromFireStore(postDoc);

    setState(() {
      _isCurrentUserPost = currentUser.uid == post.authorId;
    });

    if (!_isCurrentUserPost) {
      try {
        final isFollowing = await _friendsService.isFollowing(post.authorId);
        if (mounted) setState(() => _isFollowingAuthor = isFollowing);
      } catch (e) {
        debugPrint('Error checking follow status: $e');
      }
    }
  }

  Future<void> _toggleFollow(String authorId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to follow users')),
      );
      return;
    }
    try {
      if (_isFollowingAuthor) {
        await _friendsService.unfollowUser(authorId);
        setState(() => _isFollowingAuthor = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed successfully')));
      } else {
        await _friendsService.followUser(authorId);
        setState(() => _isFollowingAuthor = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Followed successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e')));
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Post does not exist.'));
          final post = PostModel.fromFireStore(snapshot.data!);

          final currentUser = _auth.currentUser;
          if (currentUser != null) _isCurrentUserPost = currentUser.uid == post.authorId;

          return Column(
            children: [
              _buildAppBar(post),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (post.hasImage && post.imageUrl.isNotEmpty) _buildDetailImage(post.imageUrl),
                        const SizedBox(height: 12),
                        Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(_formatDetailTimestamp(post.createdAt), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const Spacer(),
                            if (post.type == 'alert')
                              Chip(
                                label: Text(post.isResolved ? 'Resolved' : 'Unresolved', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: post.isResolved ? Colors.green : Colors.red,
                              ),
                            if (post.type == 'event') _buildEventJoinButton(post),
                          ],
                        ),
                        const Divider(thickness: 2, color: Colors.grey, height: 40),
                        Row(
                          children: [
                            const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('comments').where('postId', isEqualTo: widget.postId).snapshots(),
                              builder: (context, snap) {
                                final count = snap.data?.docs.length ?? 0;
                                return Text('($count)', style: const TextStyle(fontSize: 16, color: Colors.grey));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCommentsList(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomActionBar(post),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PostModel post) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: GestureDetector(
            onTap: () => _navigateToProfile(post.authorId),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: AppColors.accent.withOpacity(0.2), child: Text(post.authorName[0], style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Text(post.authorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            if (_auth.currentUser != null && !_isCurrentUserPost) _buildFollowButton(post.authorId),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Text(_getTypeLabel(post.type), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(String authorId) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _toggleFollow(authorId),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowingAuthor ? Colors.green : Colors.white,
          foregroundColor: _isFollowingAuthor ? Colors.white : Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          side: BorderSide(color: _isFollowingAuthor ? Colors.white : Colors.green, width: 1.5),
        ),
        child: Text(_isFollowingAuthor ? 'Following' : 'Follow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEventJoinButton(PostModel post) {
    final communityService = CommunityService();
    final currentUserId = _auth.currentUser?.uid ?? '';
    final isOwnPost = currentUserId == post.authorId;

    return FutureBuilder<bool>(
      future: communityService.isUserJoined(widget.postId),
      builder: (context, snapshot) {
        final isJoined = snapshot.data ?? false;
        if (isOwnPost) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(left: 12),
          child: ElevatedButton(
            onPressed: () {
              communityService.joinEvent(widget.postId, widget.postId, context,
                  eventTitle: post.title, eventTime: post.eventTime ?? DateTime.now().add(const Duration(hours: 1)), eventDescription: post.eventDescription ?? post.content, authorName: post.authorName);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isJoined ? 'Left ${post.title}' : 'Joined ${post.title}')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: isJoined ? Colors.grey : Colors.green),
            child: Text(isJoined ? 'Joined' : 'Join'),
          ),
        );
      },
    );
  }

  Widget _buildDetailImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(height: 300, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
      errorWidget: (context, url, error) => Container(height: 300, color: Colors.grey[200], child: const Icon(Icons.error, size: 50, color: Colors.grey)),
    );
  }

  Widget _buildBottomActionBar(PostModel post) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primary, border: Border(top: BorderSide(color: AppColors.accent, width: 2))),
      child: Row(
        children: [
          LikeButtonWidget(postId: widget.postId, initialLikes: post.likes),
          const SizedBox(width: 4),
          Text('${post.likes}', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            color: AppColors.accent,
            onPressed: () {
              _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            },
          ),
          const SizedBox(width: 4),
          Text('${post.comments}', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(hintText: 'Write a comment...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              onTap: () {
                _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
            ),
          ),
          const SizedBox(width: 8),
          _isLoadingComment
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
              : IconButton(icon: const Icon(Icons.send), color: AppColors.accent, onPressed: _addComment),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('comments').where('postId', isEqualTo: widget.postId).orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No comments yet.', textAlign: TextAlign.center));

        final comments = snapshot.data!.docs.map((doc) => CommentModel.fromFireStore(doc)).toList();
        return Column(children: comments.map(_buildCommentItem).toList());
      },
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final isCurrentUser = _auth.currentUser?.uid == comment.authorId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(comment.authorId),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: AppColors.accent.withOpacity(0.2), child: Text(comment.authorName[0], style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(comment.content),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_formatCommentTimestamp(comment.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              CommentLikeButton(commentId: comment.id!, initialLikes: comment.likes),
              if (isCurrentUser)
                IconButton(onPressed: () => _deleteComment(comment), icon: const Icon(Icons.delete, size: 18), color: Colors.red, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to comment')));
      return;
    }

    setState(() => _isLoadingComment = true);
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'];
      final comment = CommentModel(postId: widget.postId, authorId: user.uid, authorName: username, content: content, createdAt: Timestamp.now());
      await _firestore.collection('comments').add(comment.toMap());
      await _firestore.collection('posts').doc(widget.postId).update({'comments': FieldValue.increment(1)});
      _commentController.clear();
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    } finally {
      setState(() => _isLoadingComment = false);
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.collection('comments').doc(comment.id).delete();
      await _firestore.collection('posts').doc(widget.postId).update({'comments': FieldValue.increment(-1)});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  String _formatDetailTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.year}-${date.month}-${date.day}';
  }

  String _formatCommentTimestamp(Timestamp timestamp) => _formatDetailTimestamp(timestamp);

  String _getTypeLabel(String type) {
    return {'alert': 'Alert', 'discussion': 'Discussion', 'event': 'Event'}[type] ?? type;
  }
}

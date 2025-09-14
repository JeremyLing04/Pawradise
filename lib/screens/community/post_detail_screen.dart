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
import 'profile_screen.dart'; // 导入 ProfileScreen

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoadingComment = false;
  bool _showComments = false;
  final ScrollController _scrollController = ScrollController();
  // 在类顶部添加这些变量
  bool _isFollowingAuthor = false;
  bool _isCurrentUserPost = false;
  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    // 页面加载时自动展开评论
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showComments = true);
      _checkIfCurrentUserPost();
      _checkFollowStatus();
    });
  }

  void _checkIfCurrentUserPost(){
    final currentUser = _auth.currentUser;
    if(currentUser != null){

    }
  }

  // 检查关注状态
  Future<void> _checkFollowStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 等待帖子数据加载
    final postDoc = await _firestore.collection('posts').doc(widget.postId).get();
    if (!postDoc.exists) return;

    final post = PostModel.fromFireStore(postDoc);
    setState(() {
      _isCurrentUserPost = currentUser.uid == post.authorId;
    });

    if (!_isCurrentUserPost) {
      try {
        final isFollowing = await _friendsService.isFollowing(post.authorId);
        if (mounted) {
          setState(() {
            _isFollowingAuthor = isFollowing;
          });
        }
      } catch (e) {
        debugPrint('Error checking follow status: $e');
      }
    }
  }

  // 构建关注按钮 - 文字样式
  Widget _buildFollowButton(String authorId) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        height: 32,
        child: ElevatedButton(
          onPressed: () => _toggleFollow(authorId),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFollowingAuthor ? Colors.green : Colors.white,
            foregroundColor: _isFollowingAuthor ? Colors.white : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            side: BorderSide(
              color: _isFollowingAuthor ? Colors.white : Colors.green,
              width: 1.5,
            ),
          ),
          child: Text(
            _isFollowingAuthor ? 'Following' : 'Follow',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isFollowingAuthor ? Colors.white : Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  // 切换关注状态
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
        if (mounted) {
          setState(() {
            _isFollowingAuthor = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unfollowed successfully')),
        );
      } else {
        await _friendsService.followUser(authorId);
        if (mounted) {
          setState(() {
            _isFollowingAuthor = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Followed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: $e')),
      );
    }
  }

  // 构建自定义 App Bar
  PreferredSizeWidget _buildAppBar(PostModel post) {
    return AppBar(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(post.authorId),
        child: Row(
          children: [
            // 用户头像 - 可点击
            GestureDetector(
              onTap: () => _navigateToProfile(post.authorId),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  post.authorName[0],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 用户名 - 可点击
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToProfile(post.authorId),
                child: Text(
                  post.authorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 如果不是当前用户的帖子，显示关注按钮
        if (_auth.currentUser != null && _auth.currentUser!.uid != post.authorId)
          _buildFollowButton(post.authorId),
        
        // 帖子类型徽章
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getTypeLabel(post.type),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // 导航到用户个人资料页面
  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.hasError) {
            return Center(child: Text('Error: ${postSnapshot.error}'));
          }

          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
            return const Center(child: Text('Post does not exist.'));
          }

          final post = PostModel.fromFireStore(postSnapshot.data!);
          
          // 检查是否是当前用户的帖子
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            _isCurrentUserPost = currentUser.uid == post.authorId;
          }
          
          return Column(
            children: [
              // 自定义 App Bar
              _buildAppBar(post),

              // 帖子内容（可滚动）
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (post.hasImage && post.imageUrl.isNotEmpty)
                        _buildDetailImage(post.imageUrl),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 16),

                            // 发布时间信息
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDetailTimestamp(post.createdAt),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                if (post.type == 'alert')
                                  Chip(
                                    label: Text(
                                      post.isResolved ? 'Resolved' : 'Unresolved',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: post.isResolved ? Colors.green : Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),

                                if (post.type == 'event')
                                  Container(
                                    margin: const EdgeInsets.only(left: 20),
                                    child: _buildEventJoinButton(post),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 分割线 - 分隔帖子和评论
                            Divider(
                              thickness: 2,
                              color: Colors.grey[300],
                              height: 40,
                            ),

                            // 评论列表标题
                            Row(
                              children: [
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore
                                      .collection('comments')
                                      .where('postId', isEqualTo: widget.postId)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.docs.length ?? 0;
                                    return Text(
                                      '($count)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 评论列表
                            _buildCommentsList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 固定在底部的互动栏
              _buildBottomActionBar(post),
            ],
          );
        },
      ),
    );
  }
  
  // 构建事件加入按钮
  Widget _buildEventJoinButton(PostModel post) {
    final CommunityService communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnPost = currentUserId == post.authorId;

    return FutureBuilder<int>(
      future: communityService.getParticipantCount(widget.postId),
      builder: (context, countSnapshot) {
        final participantCount = countSnapshot.data ?? 0;

        return Row(
          children: [
            // 参加人数徽章...
            
            // 加入按钮
            if (!isOwnPost) 
              FutureBuilder<bool>(
                future: communityService.isUserJoined(widget.postId),
                builder: (context, joinSnapshot) {
                  final isJoined = joinSnapshot.data ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        communityService.joinEvent(
                          widget.postId, 
                          widget.postId, 
                          context,
                          eventTitle: post.title,
                          eventTime: post.eventTime ?? DateTime.now().add(Duration(hours: 1)),
                          eventDescription: post.eventDescription ?? post.content,
                          authorName: post.authorName,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isJoined ? 'Left ${post.title}' : 'Joined ${post.title}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        isJoined ? 'Joined' : 'Join',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // 固定在底部的互动栏
  Widget _buildBottomActionBar(PostModel post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 点赞按钮
          LikeButtonWidget(
            postId: widget.postId,
            initialLikes: post.likes,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.likes}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          
          // 评论按钮
          IconButton(
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            icon: const Icon(Icons.comment_outlined),
            color: Colors.green,
            iconSize: 24,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.comments}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          
          // 评论输入框
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // 发送按钮
          _isLoadingComment
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
              : IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                ),
        ],
      ),
    );
  }

  // 构建评论列表
  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('comments')
          .where('postId', isEqualTo: widget.postId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No comments yet. Be the first to comment!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final comment = CommentModel.fromFireStore(doc);
            return _buildCommentItem(comment);
          }).toList(),
        );
      },
    );
  }

  // 构建单个评论项 - 添加点击跳转到用户资料功能
  Widget _buildCommentItem(CommentModel comment) {
    final isCurrentUser = _auth.currentUser?.uid == comment.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行 - 可点击
          GestureDetector(
            onTap: () => _navigateToProfile(comment.authorId),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Text(
                    comment.authorName[0],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatCommentTimestamp(comment.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              // 使用评论点赞组件
              CommentLikeButton(
                commentId: comment.id!,
                initialLikes: comment.likes,
              ),
              const SizedBox(width: 8),
              if (isCurrentUser)
                IconButton(
                  onPressed: () => _deleteComment(comment),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 添加评论
  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    setState(() => _isLoadingComment = true);

    try {
      // 获取用户信息
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc['username'];

      // 创建评论
      final comment = CommentModel(
        postId: widget.postId,
        authorId: user.uid,
        authorName: username,
        content: content,
        createdAt: Timestamp.now(),
      );

      // 保存评论
      await _firestore.collection('comments').add(comment.toMap());

      // 更新帖子的评论计数
      await _firestore.collection('posts').doc(widget.postId).update({
        'comments': FieldValue.increment(1),
      });

      _commentController.clear();
      
      // 自动滚动到底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      setState(() => _isLoadingComment = false);
    }
  }

  // 删除评论
  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
        // 删除评论
        await _firestore.collection('comments').doc(comment.id).delete();

        // 更新帖子的评论计数
        await _firestore.collection('posts').doc(widget.postId).update({
          'comments': FieldValue.increment(-1),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCommentTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
// screens/profile/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/models/post_model.dart';
import 'package:pawradise/screens/community/post_detail_screen.dart';
import 'package:pawradise/screens/community/widgets/post_card.dart';
import '../../constants.dart';
import '../../services/friends_service.dart';
import 'profile_header.dart';
import 'profile_pets_tab.dart';
import 'profile_posts_tab.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // 可为null，表示当前用户
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendsService _friendsService = FriendsService();
  
  late TabController _tabController;
  String? _displayUserId;
  
  // 用户信息
  String _name = "";
  String _username = ""; // 新增username字段
  String? _userAvatarUrl;
  String _userBio = "";
  
  // 统计数据
  int _postsCount = 0;
  int _followingCount = 0;
  int _followersCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    _determineUserId();
    _loadUserData();
    _loadStats();
    _checkFollowStatus();
  }

  void _determineUserId() {
    setState(() {
      _displayUserId = widget.userId ?? _auth.currentUser?.uid;
    });
  }

  Future<void> _loadUserData() async {
    if (_displayUserId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_displayUserId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _name = data?['name'] ?? data?['username'] ?? 'User';
          _username = data?['username'] ?? 'User'; // 获取username字段
          _userAvatarUrl = data?['avatarUrl'];
          _userBio = data?['bio'] ?? "";
        });
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  Future<void> _loadStats() async {
    if (_displayUserId == null) return;
    
    try {
      final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: _displayUserId)
        .count()
        .get();

      final followingCount = await _friendsService.getFollowingCount(_displayUserId!);
      final followersCount = await _friendsService.getFollowersCount(_displayUserId!);

      setState(() {
        _postsCount = postsSnapshot.count ?? 0;
        _followingCount = followingCount;
        _followersCount = followersCount;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && _displayUserId != null && 
        currentUser.uid != _displayUserId) {
      try {
        final isFollowing = await _friendsService.isFollowing(_displayUserId!);
        setState(() {
          _isFollowing = isFollowing;
        });
      } catch (e) {
        print('Error checking follow status: $e');
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _displayUserId == null || 
        currentUser.uid == _displayUserId) return;

    try {
      if (_isFollowing) {
        await _friendsService.unfollowUser(_displayUserId!);
      } else {
        await _friendsService.followUser(_displayUserId!);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount = _isFollowing ? _followersCount + 1 : _followersCount - 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  // 添加刷新方法
  void _refreshProfileData() {
    _loadUserData();
    _loadStats();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayUserId == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final bool isOwnProfile = widget.isCurrentUser || 
        (_auth.currentUser?.uid == _displayUserId);

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _username,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          // 用户信息头部
          ProfileHeader(
            userId: _displayUserId!,
            name: _name,
            userAvatarUrl: _userAvatarUrl,
            userBio: _userBio,
            isOwnProfile: isOwnProfile,
            postsCount: _postsCount,
            followingCount: _followingCount,
            followersCount: _followersCount,
            onFollowPressed: isOwnProfile ? null : _toggleFollow,
            isFollowing: _isFollowing,
            onProfileUpdated: _refreshProfileData, // 传递刷新回调
          ),
          
          // 标签栏
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.accent,
              tabs: [
                Tab(text: 'Pets'),
                Tab(text: 'Posts'),
              ],
            ),
          ),
          
          // 内容区域
          Expanded(
            child: Container(
              color: AppColors.secondary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 宠物标签
                  ProfilePetsTab(userId: _displayUserId!, isOwnProfile: isOwnProfile),
                  
                  // 帖子标签
                  ProfilePostsTab(userId: _displayUserId!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Posts', _postsCount),
          _buildStatItem('Following', _followingCount),
          _buildStatItem('Followers', _followersCount),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green),
              ),
              child: Text(
                'Message',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.secondary,
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.accent,
        tabs: [
          Tab(text: 'Pets'),
          Tab(text: 'Posts'),
        ],
      ),
    );
  }
}
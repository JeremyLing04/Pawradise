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
  final String? userId; // null = current user
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
  
  // User info
  String _name = "";
  String _username = "";
  String? _userAvatarUrl;
  String _userBio = "";
  
  // Stats
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

  // Determine which user profile to display
  void _determineUserId() {
    setState(() {
      _displayUserId = widget.userId ?? _auth.currentUser?.uid;
    });
  }

  // Load user basic data from Firestore
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
          _username = data?['username'] ?? 'User';
          _userAvatarUrl = data?['avatarUrl'];
          _userBio = data?['bio'] ?? "";
        });
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  // Load post count and follow/follower counts
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

  // Check if current user is following the displayed user
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

  // Toggle follow/unfollow action
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
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  // Refresh profile data
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
          // Profile header with avatar, name, bio, stats
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
            onProfileUpdated: _refreshProfileData, // callback for refresh
          ),
          
          // Tab bar for Pets / Posts
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.background,
              labelColor: AppColors.background,
              unselectedLabelColor: AppColors.accent,
              tabs: [
                Tab(text: 'Pets'),
                Tab(text: 'Posts'),
              ],
            ),
          ),
          
          // Tab views
          Expanded(
            child: Container(
              color: AppColors.secondary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  ProfilePetsTab(userId: _displayUserId!, isOwnProfile: isOwnProfile),
                  ProfilePostsTab(userId: _displayUserId!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

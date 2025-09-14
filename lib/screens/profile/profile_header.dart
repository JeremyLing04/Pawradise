// screens/profile/profile_header.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawradise/screens/community/chat_screen.dart';
import 'package:pawradise/services/chat_service.dart';
import 'dart:io';
import '../../constants.dart';

class ProfileHeader extends StatefulWidget {
  final String userId;
  final String name;
  final String? userAvatarUrl;
  final String userBio;
  final bool isOwnProfile;
  final int postsCount;
  final int followingCount;
  final int followersCount;
  final VoidCallback? onFollowPressed;
  final bool isFollowing;
  final VoidCallback? onProfileUpdated; // 添加刷新回调

  const ProfileHeader({
    super.key,
    required this.userId,
    required this.name,
    this.userAvatarUrl,
    required this.userBio,
    required this.isOwnProfile,
    required this.postsCount,
    required this.followingCount,
    required this.followersCount,
    this.onFollowPressed,
    this.isFollowing = false,
    this.onProfileUpdated, // 添加刷新回调
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化时设置当前值
    _nameController.text = widget.name;
    _bioController.text = widget.userBio;
  }

  void _showEditProfileDialog() {
    // 每次显示对话框时更新值为最新
    _nameController.text = widget.name;
    _bioController.text = widget.userBio;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 头像编辑
                GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: widget.userAvatarUrl != null
                            ? NetworkImage(widget.userAvatarUrl!)
                            : null,
                        child: _isUploadingAvatar
                            ? CircularProgressIndicator()
                            : widget.userAvatarUrl == null
                                ? Icon(Icons.person, size: 40)
                                : null,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Change Photo',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // 名称编辑
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                // Bio编辑
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    try {
      // 更新Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'name': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // 更新Firebase Auth中的显示名称
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      
      Navigator.pop(context);
      
      // 通知父组件刷新数据
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  // 其他方法保持不变...
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          if (widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty)
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeAvatar();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${widget.userId}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 更新Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'avatarUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // 通知父组件刷新
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
      
      setState(() {
        _isUploadingAvatar = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
      
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload avatar: $e')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    try {
      // 删除存储中的文件
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${widget.userId}.jpg');
        await storageRef.delete();
      } catch (e) {
        print('File not found in storage: $e');
      }
      
      // 更新Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'avatarUrl': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // 通知父组件刷新
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture removed successfully!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove avatar: $e')),
      );
    }
  }

  // build 方法保持不变...
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: AppColors.primary,
      child: Column(
        children: [
          // 第一行：头像 + 名称 + 统计数据
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty
                      ? Image.network(
                          widget.userAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              
              SizedBox(width: 16),
              
              // 名称和统计数据
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户名 - 与统计数据对齐
                    Container(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // 统计数据
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Posts', widget.postsCount),
                        _buildStatItem('Following', widget.followingCount),
                        _buildStatItem('Followers', widget.followersCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Bio - 左对齐
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.userBio.isEmpty ? 'No bio yet' : widget.userBio,
              style: TextStyle(
                color: AppColors.accent,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          
          SizedBox(height: 16),
          
          // 操作按钮 - 扁平且与父级同宽
          if (widget.isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showEditProfileDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Edit Profile'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onFollowPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isFollowing ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.isFollowing ? 'Following' : 'Follow'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { _startChatWithUser(widget.userId, widget.name); },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Message',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
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

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

    // 新增：开始与用户聊天的方法
  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 获取或创建聊天室
      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      
      // 导航到聊天界面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }
}
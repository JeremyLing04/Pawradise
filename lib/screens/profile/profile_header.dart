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
  final VoidCallback? onProfileUpdated;

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
    this.onProfileUpdated, 
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
    _nameController.text = widget.name;
    _bioController.text = widget.userBio;
  }

  /// Show edit profile dialog
  void _showEditProfileDialog() {
    _nameController.text = widget.name;
    _bioController.text = widget.userBio;

    showDialog(
      context: context,
      builder: (context) {
          return AlertDialog(
          backgroundColor: AppColors.secondary.withOpacity(0.9), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: AppColors.accent, width: 2),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(color: AppColors.accent),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile photo picker
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
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Name input field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    fillColor: AppColors.background.withOpacity(0.5), 
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                // Bio input field
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    fillColor: AppColors.background.withOpacity(0.5), 
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

  /// Save profile changes to Firestore and Firebase Auth
  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'name': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      
      Navigator.pop(context);
      
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green, 
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red, 
        ),
      );
    }
  }

  /// Show options to change avatar
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

  /// Pick image from camera or gallery
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

  /// Upload avatar to Firebase Storage and update Firestore
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
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'avatarUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
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

  /// Remove avatar from Storage and Firestore
  Future<void> _removeAvatar() async {
    try {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${widget.userId}.jpg');
        await storageRef.delete();
      } catch (e) {
        print('File not found in storage: $e');
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'avatarUrl': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with border and shadow
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
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          
          // User bio
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
          
          // Edit profile or Follow/Message buttons
          if (widget.isOwnProfile)
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showEditProfileDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent, width: 2),
                    foregroundColor: AppColors.accent,
                    backgroundColor: AppColors.secondary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
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

  /// Build stat item (Posts / Following / Followers)
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.background,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  /// Default avatar when user has no photo
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

  /// Start chat with another user
  Future<void> _startChatWithUser(String otherUserId, String otherUserName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final chatRoomId = await _chatService.getOrCreateChatRoom(otherUserId, otherUserName);
      
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

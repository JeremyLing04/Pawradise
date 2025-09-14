// screens/profile/pet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../constants.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import 'add_edit_pet_screen.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> with SingleTickerProviderStateMixin {
  final PetService _petService = PetService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  String? _userId;
  String _userName = "";
  String? _userAvatarUrl;
  StreamSubscription<User?>? _authSubscription;
  bool _isUploadingAvatar = false;
  String _userBio = "";
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  late TabController _tabController;
  
  List<Pet> _pets = [];
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    
    _getCurrentUserImmediately();
    
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setUserData(user);
      } else {
        setState(() {
          _userId = null;
          _userName = "Pet Lover";
          _userAvatarUrl = null;
        });
      }
    });
  }

  void _getCurrentUserImmediately() {
    final user = _auth.currentUser;
    if (user != null) {
      _setUserData(user);
    }
  }

  void _setUserData(User user) async {
    setState(() {
      _userId = user.uid;
      _userName = user.displayName ?? 
                (user.email != null ? user.email!.split('@')[0] : "Pet Lover");
      _userAvatarUrl = user.photoURL;
      _nameController.text = _userName;
    });
    
    await _loadUserDataFromFirestore();
  }

  Future<void> _loadUserDataFromFirestore() async {
    if (_userId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _userBio = data?['bio'] ?? "";
          _bioController.text = _userBio;
          if (_userAvatarUrl == null && data?['avatarUrl'] != null) {
            _userAvatarUrl = data?['avatarUrl'];
          }
          if (data?['name'] != null) {
            _userName = data?['name'];
            _nameController.text = _userName;
          }
        });
      }
    } catch (e) {
      print('Failed to load user data from Firestore: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    if (_userId == null) return;
    
    try {
      // 更新 Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
            'name': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // 更新 Firebase Auth 中的显示名称
      await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      
      setState(() {
        _userName = _nameController.text.trim();
        _userBio = _bioController.text.trim();
        _isEditingProfile = false;
      });
      
      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    }
  }

  void _toggleEditProfile() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (!_isEditingProfile) {
        // 取消编辑时恢复原值
        _nameController.text = _userName;
        _bioController.text = _userBio;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _bioController.dispose();
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAvatarOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty)
                  _buildAvatarOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    onTap: _removeAvatar,
                    color: Colors.red,
                  ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: color ?? AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    
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
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

Future<void> _uploadAvatar(File imageFile) async {
  if (_userId == null) return;
  
  setState(() {
    _isUploadingAvatar = true;
  });

  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_avatars')
        .child('$_userId.jpg');

    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    await _auth.currentUser?.updatePhotoURL(downloadUrl);
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .update({
          'avatarUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    
    await _auth.currentUser?.reload();
    
    setState(() {
      _userAvatarUrl = downloadUrl;
      _isUploadingAvatar = false;
    });
    
    _showSuccessSnackBar('Profile picture updated successfully!');
    
  } catch (e) {
    setState(() {
      _isUploadingAvatar = false;
    });
    _showErrorSnackBar('Failed to upload avatar: $e');
  }
}

Future<void> _removeAvatar() async {
  Navigator.pop(context);
  
  if (_userId == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove Profile Picture'),
      content: Text('Are you sure you want to remove your profile picture?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('$_userId.jpg');
        await storageRef.delete();
      } catch (e) {
        print('File not found in storage: $e');
      }
      
      await _auth.currentUser?.updatePhotoURL(null);
      
      await _removeAvatarUrlFromFirestore();
      
      await _auth.currentUser?.reload();
      
      setState(() {
        _userAvatarUrl = null;
        _isUploadingAvatar = false;
      });
      
      _showSuccessSnackBar('Profile picture removed successfully!');
      
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      _showErrorSnackBar('Failed to remove avatar: $e');
    }
  }
}

  Future<void> _removeAvatarUrlFromFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
            'avatarUrl': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to remove avatar URL from Firestore: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToAddPet() {
    if (_userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(), 
      ),
    ).then((_) {
      // 刷新宠物列表
      setState(() {});
    });
  }

  void _navigateToEditPet(Pet pet) {
    if (_userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(pet: pet),
      ),
    ).then((_) {
      // 刷新宠物列表
      setState(() {});
    });
  }

  // Add the missing method
  Widget _buildUserPostsTab() {
    return _PostsTabContent(userId: _userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditingProfile ? Icons.check : Icons.edit, color: AppColors.accent),
            onPressed: _isEditingProfile ? _saveUserProfile : _toggleEditProfile,
            tooltip: _isEditingProfile ? 'Save Profile' : 'Edit Profile',
          ),
        ],
      ),
      backgroundColor: AppColors.secondary,
      body: StreamBuilder<List<Pet>>(
        stream: _petService.getPetsByUserStream(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading pets: ${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: AppColors.accent),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          _pets = snapshot.data ?? [];
          
          return Column(
            children: [
              _buildUserWelcome(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pets List
                    _buildPetTabContent(_pets),

                    // Tab 2: User Posts
                    _buildUserPostsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserWelcome() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      color: AppColors.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserAvatar(),
          SizedBox(height: 10),
          _isEditingProfile
              ? TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
          SizedBox(height: 6),
          Container(
            width: 80,
            height: 2,
            color: AppColors.secondary,
          ),
          SizedBox(height: 8),
          _buildBioSection(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.secondary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.accent.withAlpha(150),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        indicatorPadding: EdgeInsets.symmetric(horizontal: 20),
        tabs: [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('My Pets'), // 原本是 My Posts
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('My Posts'), // 原本是 My Pets
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetTabContent(List<Pet> pets) {
    return pets.isEmpty
        ? _buildEmptyState()
        : ListView(
            padding: EdgeInsets.only(bottom: 16),
            children: [
              // 宠物数量信息 - 现在在列表顶部，会随列表滚动
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'Caring for ${pets.length} adorable pet${pets.length > 1 ? 's' : ''} ❤️',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 宠物列表
              ...pets.map((pet) => _buildPetCard(pet)).toList(),
              
              // 添加新宠物按钮（在列表底部）
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.add, size: 20),
                  label: Text(
                    'Add New Pet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(80),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Icon(
              Icons.pets,
              size: 60,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 25),
          Text(
            'No Pets Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your furry friends will appear here\nStart by adding your first pet!',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          // 在空状态下添加一个按钮
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                'Add Your First Pet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return GestureDetector(
      onTap: _isEditingProfile ? () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Edit Bio'),
              content: TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself and your pets...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _userBio = _bioController.text;
                    });
                    Navigator.pop(context);
                    _saveUserProfile(); // 保存更改
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      } : null, // 不在编辑模式时，onTap 为 null，不会响应点击
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Me',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                _isEditingProfile
                    ? Icon(Icons.edit, size: 14, color: AppColors.accent.withAlpha(150))
                    : SizedBox(),
              ],
            ),
            SizedBox(height: 6),
            _isEditingProfile
                ? TextFormField(
                    controller: _bioController,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Tell us about yourself and your pets...',
                      hintStyle: TextStyle(
                        color: AppColors.accent.withAlpha(150),
                      ),
                    ),
                  )
                : Text(
                    _userBio.isEmpty ? 'Tap to add a bio...' : _userBio,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _isEditingProfile ? _showAvatarOptions : null,
          child: Container(
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
              child: _isUploadingAvatar
                  ? Container(
                      color: AppColors.secondary,
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    )
                  : (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty)
                      ? Image.network(
                          _userAvatarUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
        ),
        if (_isEditingProfile)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 12,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
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

 Widget _buildPetCard(Pet pet) {
  return Container(
    margin: EdgeInsets.only(bottom: 18),
    child: Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: AppColors.background,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPetImage(pet),
              SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_nature, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              pet.breed,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cake, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              '${pet.age} years',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        '📝 ${pet.notes!}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary.withAlpha(180),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              
              // 只有编辑图标有点击事件
              InkWell(
                onTap: () => _navigateToEditPet(pet),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit, size: 22, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPetImage(Pet pet) {
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _getPetColor(pet),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(60),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(pet.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _getPetColor(pet),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(60),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.pets,
          size: 30,
          color: AppColors.background,
        ),
      );
    }
  }

  Color _getPetColor(Pet pet) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
    ];
    
    final index = pet.name.length % colors.length;
    return colors[index];
  }
}

// 创建一个单独的Widget来保持Posts tab的状态
class _PostsTabContent extends StatefulWidget {
  final String? userId;

  const _PostsTabContent({this.userId});

  @override
  __PostsTabContentState createState() => __PostsTabContentState();
}

class __PostsTabContentState extends State<_PostsTabContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.userId == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading posts',
              style: TextStyle(color: AppColors.accent),
            ),
          );
        }
        
        final posts = snapshot.data?.docs ?? [];
        
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 60, color: AppColors.primary.withAlpha(120)),
                SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Share your pet moments with the community!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            return _buildPostCard(post, posts[index].id);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 帖子图片
          if (post['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                post['imageUrl'],
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.secondary,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.secondary,
                    child: Icon(
                      Icons.error,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          
          // 帖子内容
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                if (post['title'] != null && post['title'].isNotEmpty)
                  Text(
                    post['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                
                SizedBox(height: 8),
                
                // 内容
                if (post['content'] != null && post['content'].isNotEmpty)
                  Text(
                    post['content'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                SizedBox(height: 12),
                
                // 互动信息
                Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      '${post['likes']?.length ?? 0}',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '${post['commentCount'] ?? 0}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Spacer(),
                    Text(
                      _formatTimestamp(post['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
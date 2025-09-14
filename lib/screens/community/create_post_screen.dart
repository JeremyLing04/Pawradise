import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/post_model.dart'; // 导入 PostModel

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _keywordController = TextEditingController();
  String _selectedType = 'discussion';
  bool _isLoading = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  List<String> _keywords = [];

  final _postTypes = [
    {'value': 'discussion', 'label': 'Discussion'},
    {'value': 'alert', 'label': 'Alert'},
    {'value': 'event', 'label': 'Event'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 帖子类型选择
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Post Category',
                  border: OutlineInputBorder(),
                ),
                items: _postTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),

              // 图片上传部分
              _buildImageSection(),
              const SizedBox(height: 16),

              // 标题输入
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 内容输入
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 关键词部分
              _buildKeywordsSection(),
              const SizedBox(height: 24),

              // 发布按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const Text(
          'Keywords',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // 关键词输入和添加按钮
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _keywordController,
                decoration: InputDecoration(
                  hintText: 'Add keyword...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: _addKeyword,
                  ),
                ),
                onFieldSubmitted: (_) => _addKeyword(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addKeyword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 已添加的关键词标签
        if (_keywords.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: Colors.green[50],
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeKeyword(keyword),
                labelStyle: const TextStyle(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green[300]!),
                ),
              );
            }).toList(),
          ),
        
        // 提示文本
        if (_keywords.isEmpty)
          Text(
            'Add keywords to help others find your post',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String imageUrl = '';
      bool hasImage = false;

      // 如果有选择图片，先上传图片
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _uploadImage(_selectedImage!);
        hasImage = true;
        setState(() => _isUploadingImage = false);
      }

      // 生成自动关键词 + 用户手动添加的关键词
      final autoKeywords = PostModel.generateKeywords(
        _titleController.text, 
        _contentController.text
      );
      final allKeywords = {...autoKeywords, ..._keywords}.toList();

      // 使用 PostModel 创建帖子对象
      final newPost = PostModel(
        authorId: user.uid,
        authorName: userDoc['username'],
        title: _titleController.text,
        content: _contentController.text,
        type: _selectedType,
        likes: 0,
        comments: 0,
        isResolved: false,
        createdAt: Timestamp.now(),
        hasImage: hasImage,
        imageUrl: imageUrl,
        keywords: allKeywords, // 包含自动生成和手动添加的关键词
      );

      // 保存到 Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .add(newPost.toMap());

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post Failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_selectedImage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Select Image"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.green),
            ),
          ),
        ),
        if (_isUploadingImage)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          )
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final String fileName = 'posts/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Upload Error: $e');
      rethrow;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'discussion';
  bool _isLoading = false;
  File? _selectedImage;
  bool _isUploadingImage = false;

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
          child: Column(
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

              // 图片上传提示（后续可以扩展为实际的上传功能）
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

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': userDoc['username'],
        'title': _titleController.text,
        'content': _contentController.text,
        'type': _selectedType,
        'likes': 0,
        'comments': 0,
        'isResolved': false,
        'createdAt': Timestamp.now(),
        'hasImage': false, // 默认没有图片
        'imageUrl': '',    // 空图片URL
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post Failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if(_selectedImage != null)
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
                      onPressed: ()=>setState(() => _selectedImage = null),
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
              side:BorderSide(color: Colors.green),
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
    try{
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if(image != null){
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }
}
// screens/profile/add_edit_pet_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import '../../constants.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';

class AddEditPetScreen extends StatefulWidget {
  final Pet? pet;
  
  const AddEditPetScreen({super.key, this.pet}); // 移除 required userId 参数

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final PetService _petService = PetService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  File? _selectedImage;
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age.toString();
      _notesController.text = widget.pet!.notes ?? '';
    }
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pet = Pet(
        id: widget.pet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: _userId!, // 使用获取到的 userId
        name: _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        imageUrl: widget.pet?.imageUrl,
        createdAt: widget.pet?.createdAt ?? DateTime.now(),
      );

      if (widget.pet == null) {
        await _petService.addPet(pet, imageFile: _selectedImage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet added successfully!')),
        );
      } else {
        await _petService.updatePet(pet, imageFile: _selectedImage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet updated successfully!')),
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${widget.pet!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _petService.deletePet(widget.pet!.id, widget.pet!.imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet deleted successfully!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                // App Bar
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.accent),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Pet Info' : 'Add New Pet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: Icon(Icons.delete, color: AppColors.accent),
                          onPressed: _deletePet,
                        ),
                      if (!isEditing) SizedBox(width: 48),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Welcome Card with Image Picker
                          _buildWelcomeCard(isEditing),
                          SizedBox(height: 32),
                          
                          // Centered Glassmorphism Form Card
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFA78B6D),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Pet Image Picker
                                    _buildImagePicker(),
                                    SizedBox(height: 20),
                                    
                                    // Pet Name
                                    _buildTextField('Pet Name', Icons.pets, _nameController, 
                                        validator: _validateRequired),
                                    SizedBox(height: 20),
                                    
                                    // Breed & Age in a row
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildTextField('Breed', Icons.emoji_nature, _breedController, 
                                              validator: _validateRequired),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTextField('Age', Icons.cake, _ageController,
                                              keyboardType: TextInputType.number,
                                              validator: _validateAge),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    
                                    // Notes
                                    _buildTextField('Notes (optional)', Icons.notes, _notesController,
                                        maxLines: 3),
                                    SizedBox(height: 28),
                                    
                                    // Save Button
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _savePet,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent.withOpacity(0.7),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        isEditing ? 'Update Info' : 'Add to Family',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWelcomeCard(bool isEditing) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.pets,
            size: 40,
            color: AppColors.accent,
          ),
          SizedBox(height: 12),
          Text(
            isEditing 
              ? 'Update ${widget.pet!.name}\'s Info' 
              : 'Welcome a New Furry Friend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            isEditing
              ? 'For the best care ever!'
              : 'Let\'s get to know your pup!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _getImage(),
            child: _getImage() == null
                ? Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400)
                : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tap to add/change photo',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  ImageProvider? _getImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (widget.pet?.imageUrl != null) {
      return NetworkImage(widget.pet!.imageUrl!);
    }
    return null;
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // 添加以下属性来确保错误信息完整显示
        errorStyle: TextStyle(
          fontSize: 12, // 减小字体大小
          height: 1.2, // 调整行高
        ),
        errorMaxLines: 2, // 允许最多2行错误文本
      ),
    );
  }
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0 || age > 30) {
      return 'Invalid age (1-30)';
    }
    return null;
  }
}
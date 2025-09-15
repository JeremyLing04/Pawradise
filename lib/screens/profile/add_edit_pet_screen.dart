import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import '../../constants.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import '../../services/ai_service.dart';

class AddEditPetScreen extends StatefulWidget {
  final Pet? pet;
  
  const AddEditPetScreen({super.key, this.pet});

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
  bool _isIdentifyingBreed = false;
  String? _userId;
  String? _aiSuggestedBreed;

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

  /// Get current logged-in user ID
  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  /// Pick image from gallery and identify breed via AI
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isIdentifyingBreed = true;
      });
    }

    try {
      final suggestedBreed = await AIService.identifyDogBreed(_selectedImage!);

      if (mounted) {
        setState(() {
          _aiSuggestedBreed = suggestedBreed;
          _isIdentifyingBreed = false;
        });

        if (suggestedBreed != null && suggestedBreed != 'Unknown') {
          _showBreedConfirmationDialog(suggestedBreed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isIdentifyingBreed = false;
        });
        _showErrorSnackBar('Breed identification failed: $e');
      }
    }
  }

  /// Show dialog to confirm AI-suggested breed
  void _showBreedConfirmationDialog(String suggestedBreed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI detection result', style: TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              suggestedBreed,
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(height: 16),
            Text(
              'Is this the correct breed of your pet?',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBreedCorrectionDialog(suggestedBreed);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _breedController.text = suggestedBreed;
              });
              Navigator.pop(context);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to correct breed if AI suggestion is incorrect
  void _showBreedCorrectionDialog(String suggestedBreed) {
    final correctionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Please enter your pet\'s breed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(suggestedBreed),
            SizedBox(height: 8),
            Text('Is this not the breed? Enter the correct breed:'),
            SizedBox(height: 16),
            TextFormField(
              controller: correctionController,
              decoration: InputDecoration(
                labelText: 'Correct Breed',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (correctionController.text.isNotEmpty) {
                setState(() {
                  _breedController.text = correctionController.text;
                });
              }
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Build breed text field with AI identification progress indicator
  Widget _buildBreedField() {
    return Stack(
      children: [
        _buildTextField('Breed', Icons.emoji_nature, _breedController, 
            validator: _validateRequired),
        if (_isIdentifyingBreed)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.background),
                ),
              ),
            ),
          ),
      ],
    );
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

  /// Save new or updated pet
  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pet = Pet(
        id: widget.pet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: _userId!,
        name: _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        imageUrl: widget.pet?.imageUrl,
        createdAt: widget.pet?.createdAt ?? DateTime.now(),
      );

      if (widget.pet == null) {
        await _petService.addPet(pet, imageFile: _selectedImage);
        _showSuccessSnackBar('Pet added successfully!');
      } else {
        await _petService.updatePet(pet, imageFile: _selectedImage);
        _showSuccessSnackBar('Pet updated successfully!');
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete pet after user confirmation
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
        _showSuccessSnackBar('Pet deleted successfully!');
        Navigator.pop(context, true);
      } catch (e) {
        _showErrorSnackBar('Error: $e');
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
                          _buildWelcomeCard(isEditing),
                          SizedBox(height: 32),
                          _buildFormCard(),
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
            color: AppColors.textPrimary.withOpacity(0.1),
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

  Widget _buildFormCard() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFA78B6D), width: 2.0),
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
              _buildImagePicker(),
              SizedBox(height: 20),
              _buildTextField('Pet Name', Icons.pets, _nameController, validator: _validateRequired),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: _buildBreedField()),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      'Age', 
                      Icons.cake, 
                      _ageController,
                      keyboardType: TextInputType.number,
                      validator: _validateAge,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildTextField('Notes (optional)', Icons.notes, _notesController, maxLines: 3),
              SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent.withOpacity(0.7),
                  foregroundColor: AppColors.background,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: Text(
                  widget.pet != null ? 'Update Info' : 'Add to Family',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
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
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  ImageProvider? _getImage() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (widget.pet?.imageUrl != null) return NetworkImage(widget.pet!.imageUrl!);
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
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: TextStyle(fontSize: 12, height: 1.2),
        errorMaxLines: 2,
      ),
    );
  }
  
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final age = int.tryParse(value);
    if (age == null || age <= 0 || age > 30) return 'Invalid age (1-30)';
    return null;
  }
}

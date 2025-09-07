import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/pet_model.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age.toString();
      _notesController.text = widget.pet!.notes ?? '';
    }
  }

  void _savePet() {
    if (_formKey.currentState!.validate()) {
      final pet = Pet(
        id: widget.pet?.id ?? 'new_pet_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: 'current_user_id',
        name: _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.pet?.createdAt ?? DateTime.now(),
      );

      print('Saving pet: ${pet.name}');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary.withAlpha(30),
      appBar: AppBar(
        title: Text(
          widget.pet == null ? 'Add New Pet' : 'Edit Pet Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.accent,
        elevation: 0,
        actions: [
          if (widget.pet != null)
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.accent),
              onPressed: () => print('Delete pet'),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ 大大的可爱消息卡片
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: AppColors.primary,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 50,
                      color: AppColors.accent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.pet == null 
                        ? 'Welcome a New Furry Friend! 🐾' 
                        : 'Update ${widget.pet!.name}\'s Info 💖',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.pet == null
                        ? 'Fill in the details to add your new best friend to the family!'
                        : 'Make sure all information is up to date for the best care.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accent.withAlpha(200),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // ✅ 表单卡片
            Expanded(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _buildTextField('Pet Name', Icons.pets, _nameController, 
                            validator: _validateRequired),
                        SizedBox(height: 20),
                        _buildTextField('Breed', Icons.emoji_nature, _breedController, 
                            validator: _validateRequired),
                        SizedBox(height: 20),
                        _buildTextField('Age (years)', Icons.cake, _ageController,
                            keyboardType: TextInputType.number,
                            validator: _validateAge),
                        SizedBox(height: 20),
                        _buildTextField('Notes (optional)', Icons.notes, _notesController,
                            maxLines: 3),
                        SizedBox(height: 30),
                        
                        // ✅ 保存按钮
                        ElevatedButton(
                          onPressed: _savePet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            widget.pet == null ? 'Add to Family' : 'Update Info',
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
              ),
            ),
          ],
        ),
      ),
    );
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.secondary.withAlpha(30),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${value == _nameController.text ? 'a name' : 'the breed'}';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter age';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Please enter a valid age (1+ years)';
    }
    if (age > 30) {
      return 'That seems too old for a pet';
    }
    return null;
  }
}
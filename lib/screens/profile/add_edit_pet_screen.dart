import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/pet_model.dart';

class AddEditPetScreen extends StatefulWidget {
  final Pet? pet; // 如果是编辑，传入pet对象

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
    // 如果是编辑模式，填充数据
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age.toString();
      _notesController.text = widget.pet!.notes ?? '';
    }
  }

  void _savePet() {
    if (_formKey.currentState!.validate()) {
      // TODO: 保存到Firebase（等Firebase好了再实现）
      final pet = Pet(
        id: widget.pet?.id ?? 'new_pet_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: 'current_user_id', // 等有用户系统后替换
        name: _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.pet?.createdAt ?? DateTime.now(),
      );

      print('Saving pet: ${pet.name}');
      Navigator.pop(context); // 返回上一页
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.pet != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // TODO: 删除宠物
                print('Delete pet');
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Name', Icons.pets, _nameController, validator: _validateRequired),
              SizedBox(height: 16),
              _buildTextField('Breed', Icons.emoji_nature, _breedController, validator: _validateRequired),
              SizedBox(height: 16),
              _buildTextField('Age', Icons.cake, _ageController, 
                keyboardType: TextInputType.number,
                validator: _validateAge,
              ),
              SizedBox(height: 16),
              _buildTextField('Notes (optional)', Icons.notes, _notesController,
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Save'),
              ),
            ],
          ),
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
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.secondary.withAlpha(40),
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
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Please enter a valid age';
    }
    return null;
  }
}
// screens/profile/pet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 添加导入
import '../../constants.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import 'add_edit_pet_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key}); // 移除 required userId 参数

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final String _userName = "ShengHan";
  final PetService _petService = PetService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  void _navigateToAddPet() {
    if (_userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(), 
      ),
    );
  }

  void _navigateToEditPet(Pet pet) {
    if (_userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(pet: pet), // 使用获取到的 userId
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Furry Friends',
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
            icon: Icon(Icons.add, color: AppColors.accent),
            onPressed: _navigateToAddPet,
            tooltip: 'Add new pet',
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
                    'Error loading pets',
                    style: TextStyle(fontSize: 18, color: AppColors.accent),
                  ),
                ],
              ),
            );
          }
          
          final pets = snapshot.data ?? [];
          
          return Column(
            children: [
              _buildUserWelcome(pets),
              Expanded(
                child: pets.isEmpty
                    ? _buildEmptyState()
                    : _buildPetList(pets),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildUserWelcome(List<Pet> pets) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(100),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 40,
              color: AppColors.secondary,
            ),
            
            SizedBox(height: 10),
            
            Text(
              _userName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 10),
            
            Container(
              width: 120,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pets.isEmpty 
                  ? 'Ready to welcome your first furry friend? 🐾' 
                  : 'Caring for ${pets.length} adorable pet${pets.length > 1 ? 's' : ''} ❤️',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 宠物列表
  Widget _buildPetList(List<Pet> pets) {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(pets[index]);
      },
    );
  }

  // ✅ 空状态显示
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
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
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: _navigateToAddPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 3,
              ),
              child: Text(
                'Add Your First Pet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 宠物卡片
  Widget _buildPetCard(Pet pet) {
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: InkWell(
          onTap: () => _navigateToEditPet(pet),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 显示宠物图片或默认图标
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
                  
                  IconButton(
                    icon: Icon(Icons.edit, size: 22, color: AppColors.primary),
                    onPressed: () => _navigateToEditPet(pet),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 显示宠物图片或默认图标
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
          color: Colors.white,
        ),
      );
    }
  }

  // ✅ 根据宠物信息返回颜色
  Color _getPetColor(Pet pet) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
    ];
    
    final index = pet.name.length % colors.length;
    return colors[index];
  }
}
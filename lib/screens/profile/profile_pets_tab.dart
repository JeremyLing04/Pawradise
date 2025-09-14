// screens/profile/profile_pets_tab.dart
import 'package:flutter/material.dart';
import '../../services/pet_service.dart';
import '../../models/pet_model.dart';
import 'add_edit_pet_screen.dart';
import '../../constants.dart';

class ProfilePetsTab extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const ProfilePetsTab({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  State<ProfilePetsTab> createState() => _ProfilePetsTabState();
}

class _ProfilePetsTabState extends State<ProfilePetsTab> {
  final PetService _petService = PetService();

  void _navigateToAddPet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(), 
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _navigateToEditPet(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPetScreen(pet: pet),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildPetCard(Pet pet) {
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
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
                
                if (widget.isOwnProfile)
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
          color: Colors.white,
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
            widget.isOwnProfile 
              ? 'Your furry friends will appear here\nStart by adding your first pet!'
              : 'This user has no pets yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          if (widget.isOwnProfile)
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
                  foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pet>>(
      stream: _petService.getPetsByUserStream(widget.userId),
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
              ],
            ),
          );
        }
        
        final pets = snapshot.data ?? [];
        
        if (pets.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView(
          padding: EdgeInsets.only(bottom: 16),
          children: [
            // 宠物数量信息
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                widget.isOwnProfile
                  ? 'Caring for ${pets.length} adorable pet${pets.length > 1 ? 's' : ''} ❤️'
                  : 'Has ${pets.length} pet${pets.length > 1 ? 's' : ''}',
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
            
            // 添加新宠物按钮（只有自己的资料显示）
            if (widget.isOwnProfile)
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
                    foregroundColor: Colors.white,
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
      },
    );
  }
}
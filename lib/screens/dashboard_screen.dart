// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:pawradise/screens/map/map_screen.dart';
import '../constants.dart';
import 'community/community_screen.dart';
import 'profile/pet_list_screen.dart'; // 修改为pet_list_screen
import 'schedule/schedule_screen.dart';
import 'chat/ai_chat_screen.dart';
import 'profile/add_edit_pet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../models/pet_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          appBar: _selectedIndex == 0
              ? AppHeader.buildAppBar(
                  context: context,
                  title: "Pawradise",
                  actions: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ],
                )
              : null,
          body: _currentPage,
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // 动态生成当前页面
  Widget get _currentPage {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(FirebaseAuth.instance.currentUser?.displayName ?? "User");
      case 1:
        return CommunityScreen();
      case 2:
        return Placeholder();
      case 3:
        return Placeholder();
      case 4:
        return PetListScreen();
      default:
        return Container();
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color.fromRGBO(239, 197, 77, 1),
      unselectedItemColor: AppColors.textSecondary,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
    );
  }

  // ------------------ Dashboard Content ------------------
  Widget _buildDashboardContent(String userName) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.secondary,
                padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $userName!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome back to Pawradise",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.accent.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -50),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPetsSection(context),
                      const SizedBox(height: 24),
                      _buildRemindersBubble(),
                      const SizedBox(height: 24),
                      _buildCommunityPreview(context),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // ------------------ Pets Section ------------------
  Widget _buildPetsSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Text(
        "Please log in to see your pets",
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Pets",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: StreamBuilder<List<Pet>>(
            stream: PetService().getPetsByUserStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Row(
                  children: [
                    _buildAddPetCard(context),
                  ],
                );
              }

              final pets = snapshot.data!;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index < pets.length) {
                    final pet = pets[index];
                    return _buildPetCard(pet);
                  } else {
                    return _buildAddPetCard(context);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Card(
      elevation: 4,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent,
              backgroundImage:
                  (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                      ? NetworkImage(pet.imageUrl!)
                      : null,
              child: (pet.imageUrl == null || pet.imageUrl!.isEmpty)
                  ? Icon(Icons.pets, size: 32, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    pet.breed,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditPetScreen()),
        );
      },
      child: Card(
        elevation: 4,
        color: AppColors.primary.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 40, color: Colors.white),
              SizedBox(height: 12),
              Text(
                "Add Pet",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 今日提醒
  Widget _buildRemindersBubble() {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Reminders",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
                Icon(Icons.notifications_active, color: AppColors.accent, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBubble("🐕 Walk Buddy", "5:00 PM", AppColors.primary),
                _buildBubble("💊 Medicine", "7:00 PM", AppColors.accent),
                _buildBubble(
                    "🍖 Dinner", "6:00 PM", AppColors.primary.withOpacity(0.8)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String task, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(task,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getContrastColor(color),
                  fontSize: 14)),
          const SizedBox(width: 8),
          Text(time,
              style: TextStyle(
                  fontSize: 12,
                  color: _getContrastColor(color),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 社区动态
  Widget _buildCommunityPreview(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Community Updates",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                TextButton(
                    onPressed: () {
                      _switchToCommunity(context);
                    },
                    child: Text("View All",
                        style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 12),
            _buildCommunityPost("🐾 Missing Dog in Central Park", "15 likes"),
            _buildCommunityPost("🌳 New Dog Park Opening", "32 likes"),
            _buildCommunityPost("💉 Free Vaccination Event", "28 likes"),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPost(String title, String likes) {
    return ListTile(
      contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.forum, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(likes,
              style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 12)),
        ],
      ),
      onTap: () {
        _switchToCommunity(navigatorKey.currentContext!);
      },
    );
  }

  // 快速操作
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildActionButton(Icons.chat, "Ask PawPal", AppColors.primary, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AIChatScreen()),
              );
            }),
            _buildActionButton(Icons.add_circle, "New Post", AppColors.secondary, () {
              _switchToCommunity(context);
            }),
            _buildActionButton(
                Icons.calendar_today, "Add Event", AppColors.secondary, () {
              _switchToSchedule(context);
            }),
            _buildActionButton(Icons.place, "Find Places", AppColors.primary, () {
              _switchToMap(context);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color cardColor, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TextButton(
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: _getContrastColor(cardColor)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _getContrastColor(cardColor),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? AppColors.textPrimary : AppColors.background;
  }

  // 导航辅助方法
  void _switchToCommunity(BuildContext context) {
    setState(() => _selectedIndex = 1);
  }

  void _switchToSchedule(BuildContext context) {
    setState(() => _selectedIndex = 2);
  }

  void _switchToMap(BuildContext context) {
    setState(() => _selectedIndex = 3);
  }
}

// 全局导航key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

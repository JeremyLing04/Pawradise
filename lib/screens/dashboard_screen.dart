import 'package:flutter/material.dart';
import 'package:pawradise/screens/map/map_screen.dart';
import '../constants.dart';
import 'community/community_screen.dart';
import '';
import '';
import 'profile/pet_list_screen.dart'; // 修改为pet_list_screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // 定义所有页面 - 修改第4个页面为PetListScreen
  final List<Widget> _pages = [
    _DashboardContent(),    // 首页内容 (索引0)
    CommunityScreen(),      // 社区页面 (索引1)
    Placeholder(),       // 日程页面 (索引2)
    MapScreen(),            // 地图页面 (索引3)
    PetListScreen(),        // 修改：宠物列表页面 (索引4)
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppHeader.buildAppBar() : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 底部导航栏
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'), // 修改图标和标签
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}

// 首页内容组件（保持原来的Dashboard布局）
class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 顶部打招呼区域
        SliverToBoxAdapter(
          child: Container(
            height: 130,
            width: double.infinity,
            color: AppColors.secondary,
            padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ShengHan!",
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
        ),
        
        // 白色内容区域
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildPetsSection(context), // 传递context用于导航
                  const SizedBox(height: 24),
                  _buildRemindersBubble(),
                  const SizedBox(height: 24),
                  _buildCommunityPreview(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 宠物卡片横向列表 - 添加导航
  Widget _buildPetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Pets", style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary
        )),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPetCard("Buddy", "Golden Retriever"),
              const SizedBox(width: 12),
              _buildPetCard("Milo", "Corgi"),
              const SizedBox(width: 12),
              _buildAddPetCard(context), // 传递context
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(String name, String breed) {
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
              child: Icon(Icons.pets, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
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
                    breed,
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
        // 导航到宠物列表页面
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetListScreen()),
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
              Text("Add Pet", style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white
              )),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent
                    )),
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
                _buildBubble("🍖 Dinner", "6:00 PM", AppColors.primary.withOpacity(0.8)),
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
          Text(task, style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getContrastColor(color),
            fontSize: 14
          )),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(
            fontSize: 12, 
            color: _getContrastColor(color),
            fontWeight: FontWeight.w500
          )),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary
                    )),
                TextButton(
                  onPressed: () {
                    _switchToCommunity(context);
                  }, 
                  child: Text("View All", style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold
                  ))
                ),
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
      title: Text(title, style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w500
      )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(likes, style: TextStyle(
            color: AppColors.primary.withOpacity(0.8),
            fontSize: 12
          )),
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
        Text("Quick Actions", style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary
        )),
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
              // TODO: 跳转到AI聊天
            }),
            _buildActionButton(Icons.add_circle, "New Post", AppColors.secondary, () {
              _switchToCommunity(context);
            }),
            _buildActionButton(Icons.calendar_today, "Add Event", AppColors.accent, () {
              _switchToSchedule(context);
            }),
            _buildActionButton(Icons.place, "Find Places", AppColors.primary.withOpacity(0.7), () {
              _switchToMap(context);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color cardColor, VoidCallback onPressed) {
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
                fontSize: 14
              )
            ),
          ],
        ),
      ),
    );
  }

  // 辅助函数：根据背景色返回对比度合适的文字颜色
  Color _getContrastColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? AppColors.textPrimary : AppColors.background;
  }

  // 导航辅助方法
  void _switchToCommunity(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 1;
    });
  }

  void _switchToSchedule(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 2;
    });
  }

  void _switchToMap(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 3;
    });
  }
}

// 全局导航key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
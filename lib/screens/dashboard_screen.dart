import 'package:flutter/material.dart';
import '../constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    // 添加页面跳转逻辑
    switch (index) {
      case 0: // Home
        // 已经在首页，不需要跳转
        break;
      case 1: // Community
        // TODO: 跳转到社区页面
        break;
      case 2: // Schedule
        // TODO: 跳转到日程页面
        break;
      case 3: // Map
        // TODO: 跳转到地图页面
        break;
      case 4: // Pets
        Navigator.pushNamed(context, '/pets');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader.buildAppBar(),
      body: CustomScrollView(
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
                  SizedBox(height: 8),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.08), // 用constants色系
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _buildPetsSection(),
                    SizedBox(height: 24),
                    _buildRemindersBubble(),
                    SizedBox(height: 24),
                    _buildCommunityPreview(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),  // 左上角圆角
          topRight: Radius.circular(15), // 右上角圆角
        ),
        child: BottomNavigationBar(
          items: AppBottomBar.items,
          currentIndex: 0, // 当前选中Profile页
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  // 宠物卡片横向列表 - 使用primary颜色
  Widget _buildPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Pets", style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary
        )),
        SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPetCard("Buddy", "Golden Retriever"),
              SizedBox(width: 12),
              _buildPetCard("Milo", "Corgi"),
              SizedBox(width: 12),
              _buildAddPetCard(),
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
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.pets, size: 32, color: AppColors.primary),
            ),
            SizedBox(height: 8),

            // 用 Expanded 让文字部分自动压缩
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


  Widget _buildAddPetCard() {
    return Card(
      elevation: 4,
      color: AppColors.primary.withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 130,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 40, color: AppColors.accent),
            SizedBox(height: 12),
            Text("Add Pet", style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.accent
            )),
          ],
        ),
      ),
    );
  }

  // 今日提醒 - 使用secondary颜色
  Widget _buildRemindersBubble() {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 16),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          SizedBox(width: 8),
          Text(time, style: TextStyle(
            fontSize: 12, 
            color: _getContrastColor(color),
            fontWeight: FontWeight.w500
          )),
        ],
      ),
    );
  }

  // 社区动态 - 使用accent颜色
  Widget _buildCommunityPreview() {
    return Card(
      elevation: 4,
      color: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
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
                  onPressed: () {}, 
                  child: Text("View All", style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold
                  ))
                ),
              ],
            ),
            SizedBox(height: 12),
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
      contentPadding: EdgeInsets.only(top: 8, bottom: 8),
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
          SizedBox(width: 4),
          Text(likes, style: TextStyle(
            color: AppColors.primary.withOpacity(0.8),
            fontSize: 12
          )),
        ],
      ),
    );
  }

  // 快速操作 - 使用不同颜色交替
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions", style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary
        )),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildActionButton(Icons.chat, "Ask PawPal", AppColors.primary),
            _buildActionButton(Icons.add_circle, "New Post", AppColors.secondary),
            _buildActionButton(Icons.calendar_today, "Add Event", AppColors.accent),
            _buildActionButton(Icons.place, "Find Places", AppColors.primary.withOpacity(0.7)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color cardColor) {
    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TextButton(
        onPressed: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: _getContrastColor(cardColor)),
            SizedBox(height: 8),
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
}
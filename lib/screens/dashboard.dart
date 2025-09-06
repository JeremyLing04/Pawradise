import 'package:flutter/material.dart';
import '../constants.dart';
import 'community/community_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  // 定义页面列表
  static final List<Widget> _pages = [
    _DashboardContent(), // 首页内容 (索引0)
    CommunityScreen(),   // 社区页面 (索引1)
    Placeholder(),    // 日程页面 (索引2)
    Placeholder(),         // 地图页面 (索引3)
    Placeholder(),     // 个人页面 (索引4)
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: const Text('Pawradise'),
              centerTitle: true,
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// 首页内容组件
class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMoodSection(),
          const SizedBox(height: 24),
          _buildPetsSection(),
          const SizedBox(height: 24),
          _buildRemindersBubble(),
          const SizedBox(height: 24),
          _buildHealthStats(),
          const SizedBox(height: 24),
          _buildCommunityPreview(context),
          const SizedBox(height: 24),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  // 顶部问候 + 心情选择
  Widget _buildMoodSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hello, ShengHan!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("How are your pets today?",
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMoodEmoji("😃", "Happy"),
                _buildMoodEmoji("🙂", "Calm"),
                _buildMoodEmoji("😐", "Neutral"),
                _buildMoodEmoji("😔", "Sad"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMoodEmoji(String emoji, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.secondary.withOpacity(0.2),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // 宠物卡片横向列表
  Widget _buildPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("My Pets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPetCard("Buddy", "Golden Retriever", "🐕"),
              const SizedBox(width: 12),
              _buildPetCard("Milo", "Corgi", "🐶"),
              const SizedBox(width: 12),
              _buildAddPetCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(String name, String breed, String emoji) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.secondary.withOpacity(0.2),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(breed, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            const Text("Add Pet", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // 今日提醒 (气泡布局)
  Widget _buildRemindersBubble() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Reminders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBubble("🐕 Walk Buddy", "5:00 PM", Colors.orange.shade100),
                _buildBubble("💊 Medicine", "7:00 PM", Colors.green.shade100),
                _buildBubble("🍖 Dinner", "6:00 PM", Colors.pink.shade100),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String task, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(task, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // 宠物健康/心情统计
  Widget _buildHealthStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Buddy's Condition",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("70% - Healthy & Active",
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle("Happy", 50, Colors.orange),
                _buildStatCircle("Playful", 30, Colors.blue),
                _buildStatCircle("Hungry", 20, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String label, int percent, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.2),
          child: Text("$percent%",
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // 社区动态预览
  Widget _buildCommunityPreview(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Community Updates",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // 切换到社区页面
                    _switchToCommunity(context);
                  }, 
                  child: const Text("View All")
                ),
              ],
            ),
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.forum, color: AppColors.primary),
      title: Text(title),
      trailing: Text(likes, style: const TextStyle(color: AppColors.textSecondary)),
      onTap: () {
        // 点击帖子也可以跳转到社区
        _switchToCommunity(navigatorKey.currentContext!);
      },
    );
  }

  // 快速操作
  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionButton(Icons.chat, "Ask PawPal", () {
          // 这里可以跳转到AI聊天页面
        }),
        _buildActionButton(Icons.add_circle, "New Post", () {
          // 切换到社区页面
          _switchToCommunity(context);
        }),
        _buildActionButton(Icons.calendar_today, "Add Event", () {
          // 切换到日程页面
          _switchToSchedule(context);
        }),
        _buildActionButton(Icons.place, "Find Places", () {
          // 切换到地图页面
          _switchToMap(context);
        }),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: TextButton(
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // 导航辅助方法
  void _switchToCommunity(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 1;
    });
  }

  void _switchToSchedule(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 2;
    });
  }

  void _switchToMap(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_DashboardState>();
    dashboardState?.setState(() {
      dashboardState._selectedIndex = 3;
    });
  }
}

// 全局导航key（可选）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
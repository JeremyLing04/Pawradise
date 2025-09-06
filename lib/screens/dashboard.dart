import 'package:flutter/material.dart';
import '../constants.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pawradise'),
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodSection(),
            SizedBox(height: 24),
            _buildPetsSection(),
            SizedBox(height: 24),
            _buildRemindersBubble(),
            SizedBox(height: 24),
            _buildHealthStats(),
            SizedBox(height: 24),
            _buildCommunityPreview(),
            SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: AppBottomBar.items,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // 顶部问候 + 心情选择
  Widget _buildMoodSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, ShengHan!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("How are your pets today?",
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 16),
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
          backgroundColor: AppColors.secondary,
          child: Text(emoji, style: TextStyle(fontSize: 22)),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // 宠物卡片横向列表
  Widget _buildPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("My Pets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        SizedBox(
          height: 130,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 110,
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.pets, color: AppColors.primary),
            ),
            SizedBox(height: 8),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(breed, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 110,
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 32, color: AppColors.primary),
            SizedBox(height: 8),
            Text("Add Pet", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // 今日提醒 (气泡布局)
  Widget _buildRemindersBubble() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Reminders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBubble("🐕 Walk Buddy", "5:00 PM", Colors.orange.shade200),
                _buildBubble("💊 Medicine", "7:00 PM", Colors.green.shade200),
                _buildBubble("🍖 Dinner", "6:00 PM", Colors.pink.shade200),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String task, String time, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(task, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(time, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // 宠物健康/心情统计
  Widget _buildHealthStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Buddy’s Condition",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("70% - Healthy & Active",
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 16),
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
          backgroundColor: color.withOpacity(0.3),
          child: Text("$percent%",
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // 社区动态
  Widget _buildCommunityPreview() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Community Updates",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: Text("View All")),
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
      trailing: Text(likes, style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  // 快速操作
  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionButton(Icons.chat, "Ask PawPal", () {}),
        _buildActionButton(Icons.add_circle, "New Post", () {}),
        _buildActionButton(Icons.calendar_today, "Add Event", () {}),
        _buildActionButton(Icons.place, "Find Places", () {}),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TextButton(
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

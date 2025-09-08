import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Friends'),
                Tab(text: 'Requests'),
                Tab(text: 'Suggestions'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFriendsList(),
                  _buildRequestsList(),
                  _buildSuggestionsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendships')
          .where('followerId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        // 实现好友列表
        return const Center(child: Text('Friends List'));
      },
    );
  }

  Widget _buildRequestsList() {
    // 实现好友请求列表
    return const Center(child: Text('Friend Requests'));
  }

  Widget _buildSuggestionsList() {
    // 实现好友推荐列表
    return const Center(child: Text('Friend Suggestions'));
  }
}
// theme_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeService extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  final String? uid;

  ThemeService({this.uid});

  Future<void> loadTheme() async {
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _isDark = doc.data()?['isDark'] ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isDark': _isDark});
    }
    notifyListeners();
  }
}

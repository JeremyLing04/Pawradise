//constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFEFC54D);
  static const Color secondary = Color(0xFFF0E2B1);
  static const Color accent = Color(0xFF7C4B00);
  static const Color background = Color(0xFFFFFFFF); 
  static const Color textPrimary = Color(0xFF333333); 
  static const Color textSecondary = Color(0xFF666666); 
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.accent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.secondary.withAlpha((0.3 * 255).round()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.accent,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
          ),
        ),
      );
}

class AppHeader {
  static AppBar buildAppBar({String title = 'Pawradise', List<Widget>? actions}) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      foregroundColor: AppColors.accent,
      backgroundColor: AppColors.primary,
      actions: actions ?? [
        IconButton(
          icon: Icon(Icons.notifications, color: AppColors.accent),
          onPressed: () {},
        ),
      ],
    );
  }
}

// 在 constants.dart 中添加
class AppBottomBar {
  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.forum),
      label: 'Community',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Schedule',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Map',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pets),
      label: 'Profile',
    ),
  ];
}
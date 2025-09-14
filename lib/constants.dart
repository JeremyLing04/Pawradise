//constants.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


// 主题切换用的 ValueNotifier
final ValueNotifier<bool> isDarkNotifier = ValueNotifier(false);

class AppColors {
  // 主色（保持亮色模式黄色，暗色模式稍柔和）
  static Color get primary =>
      isDarkNotifier.value ? const Color(0xFFE6C24D) : const Color(0xFFEFC54D);

  // 次色（背景卡片等，暗色模式深一点）
  static Color get secondary =>
      isDarkNotifier.value ? const Color(0xFF3A3A3A) : const Color(0xFFF0E2B1);

  // 强调色（暗色模式偏亮的棕色）
  static Color get accent =>
      isDarkNotifier.value ? const Color.fromARGB(255, 119, 101, 75) : const Color(0xFF7C4B00);

  // 背景色
  static Color get background =>
      isDarkNotifier.value ? const Color(0xFF1C1C1C) : Colors.white;

  // 文字主色
  static Color get textPrimary =>
      isDarkNotifier.value ? const Color(0xFFEFEFEF) : const Color(0xFF333333);

  // 文字次色
  static Color get textSecondary =>
      isDarkNotifier.value ? const Color(0xFFBBBBBB) : const Color(0xFF666666);
}


class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme(
          brightness: isDarkNotifier.value ? Brightness.dark : Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.textPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textPrimary,
          error: Colors.red,
          onError: Colors.white,
          background: AppColors.background,
          onBackground: AppColors.textPrimary,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: AppColors.accent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.secondary.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
  static AppBar buildAppBar({
    required BuildContext context,
    String title = 'Pawradise',
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      foregroundColor: Colors.white, 
      backgroundColor: Theme.of(context).primaryColor,
      leading: IconButton(
        icon: Icon(Icons.settings, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const SettingsDialog(),
          );
        },
      ),
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

//setting
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondary.withOpacity(0.9), // 0.0~1.0 透明度
      title: const Text("Settings"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isDarkNotifier,
            builder: (context, isDark, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dark Mode"),
                  Switch(
                    value: isDark,
                    onChanged: (val) {
                      isDarkNotifier.value = val;
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8), // 透明一点
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );

  }
}





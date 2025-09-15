//constants.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ValueNotifier for theme switching
final ValueNotifier<bool> isDarkNotifier = ValueNotifier(false);

class AppColors {
  // Primary color (Khaki, lighter in light mode)
  static Color get primary =>
      isDarkNotifier.value ? const Color(0xFFBFA67A) : const Color.fromARGB(255, 219, 188, 145);

  // Secondary color (card background, darker in dark mode)
  static Color get secondary =>
      isDarkNotifier.value ? const Color(0xFF555555) : const Color(0xFFF0E5D2);

  // Accent color (buttons, icons)
  static Color get accent =>
      isDarkNotifier.value ? const Color(0xFFFFF8F0) : const Color.fromARGB(255, 102, 73, 51);

  // Background color
  static Color get background =>
      isDarkNotifier.value ? const Color(0xFF1C1C1C) : Colors.white;

  // Primary text color
  static Color get textPrimary =>
      isDarkNotifier.value ? const Color(0xFFDCDCDC) : const Color(0xFF333333);

  // Secondary text color
  static Color get textSecondary =>
      isDarkNotifier.value ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
}

class AppTheme {
  // Main theme
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
  // Custom app bar
  static AppBar buildAppBar({
    required BuildContext context,
    String title = 'Pawradise',
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: AppColors.background,
        ),
      ),
      centerTitle: true,
      foregroundColor: AppColors.background,
      backgroundColor: Theme.of(context).primaryColor,
      leading: IconButton(
        icon: Icon(Icons.settings, color: AppColors.background),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const SettingsDialog(),
          );
        },
      ),
      actions: actions,
    );
  }
}

// Bottom navigation bar items
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

// Settings dialog
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondary.withOpacity(0.9),
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
                backgroundColor: Colors.red.withOpacity(0.8),
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

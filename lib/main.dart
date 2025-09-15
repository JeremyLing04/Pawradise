import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/schedule/schedule_screen.dart';
import 'providers/event_provider.dart';
import 'constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'package:pawradise/screens/map/map_screen.dart';
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/add_edit_pet_screen.dart';
import 'screens/chat/ai_chat_screen.dart';
import 'screens/splash_screen.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: isDarkNotifier,
        builder: (context, isDark, _) {
          return MaterialApp(
            title: 'Pawradise',
            theme: AppTheme.theme,
            initialRoute: '/dashboard',
            routes: {
              '/splash': (context) => SplashScreen(),
              '/': (context) => const Login(),
              '/register': (context) => const Register(),
              '/dashboard': (context) => _ScreenWithChatButton(child: const DashboardScreen()),
              '/pets': (context) => _ScreenWithChatButton(child: const ProfileScreen()),
              '/pets/add': (context) => const AddEditPetScreen(),
              '/chat': (context) => const AIChatScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      )
    );
  }
}

class _ScreenWithChatButton extends StatelessWidget {
  final Widget child;

  const _ScreenWithChatButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 15,
          bottom: 180,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent.withOpacity(0.7),
            shape: const CircleBorder(),
            onPressed: () {
              Navigator.of(context).pushNamed('/chat');
            },
            tooltip: 'Ask PawPal AI',
            child: const Icon(
              Icons.auto_awesome,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'screens/schedule/schedule_screen.dart';
import 'providers/event_provider.dart';
import 'constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

//map
import 'package:pawradise/screens/map/map_screen.dart';

//auth
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';

//profile
import 'screens/profile/pet_list_screen.dart';
import 'screens/profile/add_edit_pet_screen.dart';

// chat
import 'screens/chat/ai_chat_screen.dart';
// splash screen import
import 'screens/splash_screen.dart'; // Import the SplashScreen

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
        // 可以添加其他 providers
      ],
      child: MaterialApp(
        title: 'Pawradise',
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/': (context) => Login(),
          '/register': (context) => Register(),
          '/dashboard': (context) => DashboardScreen(),
          '/pets': (context) => PetListScreen(),
          '/pets/add': (context) => AddEditPetScreen(),
          '/chat': (context) => AIChatScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// 包装组件，只在需要的屏幕上添加聊天按钮
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
              color: Colors.white
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

//auth
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';

//profile
import 'screens/profile/pet_list_screen.dart';
import 'screens/profile/add_edit_pet_screen.dart';

// chat
import 'screens/chat/ai_chat_screen.dart';

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
    return MaterialApp(
      title: 'Pawradise',
      theme: AppTheme.lightTheme,
      initialRoute: '/dashboard',
      routes: {
        '/': (context) => const Login(),
        '/register': (context) => const Register(),
        '/dashboard': (context) => const _ScreenWithChatButton(child: DashboardScreen()),
        '/pets': (context) => const _ScreenWithChatButton(child: PetListScreen()),
        '/pets/add': (context) => const AddEditPetScreen(),
        '/chat': (context) => const AIChatScreen(),
      },
      debugShowCheckedModeBanner: false,
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
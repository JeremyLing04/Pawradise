import 'package:flutter/material.dart';
import 'constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 这个文件会自动生成
import 'screens/dashboard_screen.dart';

//community
import 'screens/community/community_screen.dart';

//auth
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';

//profile
import 'models/pet_model.dart'; 
import 'screens/profile/pet_list_screen.dart';
import 'screens/profile/add_edit_pet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawradise',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/': (context) => Login(),
        '/register': (context) => Register(),
        '/dashboard': (context) => DashboardScreen(),
        '/pets': (context) => PetListScreen(), // 添加宠物列表路由
        '/pets/add': (context) => AddEditPetScreen(), // 添加宠物
        '/pets/edit': (context) => AddEditPetScreen(pet: Pet.mock()), // 编辑宠物（示例）
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
//main.dart
import 'package:flutter/material.dart';
import 'package:pawradise/screens/map/map_screen.dart';
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
      initialRoute: '/',
      routes: {
        '/': (context) => Login(),
        '/register': (context) => Register(),
        '/dashboard': (context) => DashboardScreen(),
        '/pets': (context) => PetListScreen(), 
        '/pets/add': (context) => AddEditPetScreen(), 
        // '/pets/edit': (context) {
        //   final pet = ModalRoute.of(context)!.settings.arguments as Pet;
        //   return AddEditPetScreen(pet: pet, userId: 'current_user_id');
        // },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

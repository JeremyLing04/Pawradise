import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/schedule_screen.dart';
import 'providers/event_provider.dart';
import 'constants.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'Pawradise',
        theme: AppTheme.lightTheme,
        initialRoute: '/schedule',
        routes: {
          '/schedule': (context) => const ScheduleScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

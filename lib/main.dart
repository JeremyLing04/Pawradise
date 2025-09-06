import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 初始化 Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawradise',
      home: Scaffold(
        appBar: AppBar(title: const Text('Pawradise')),
        body: const Center(child: Text('Firebase Ready 🚀')),
      ),
    );
  }
}

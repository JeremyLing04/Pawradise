import 'package:flutter/material.dart';
import 'package:pawradise/screens/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawradise',
      theme: ThemeData(
        // Custom light brown theme
        primaryColor: Color(0xFFB98C6D),  // Light brown color for the app bar and buttons
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Color(0xFFF7E4D3),  // Light background color
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFB98C6D), // Light brown color for the app bar
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFB98C6D), // Buttons also match the theme
        ),
      ),
      home: const MapScreen(),  // The MapScreen widget will be shown as the home screen
    );
  }
}

//splash_screen.dart
import 'dart:convert';
import '../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For loading assets
import 'package:lottie/lottie.dart'; // For Lottie animations

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Animation controller to control the animation
  late Animation<double> _opacityAnimation; // Opacity animation for fade-in and fade-out
  bool _isAnimationCompleted = false; // Track if the animation is completed

  late Animation<Offset> _slideAnimation; // Animation for sliding the text from left to right

  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller for the fade-in
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Duration for the animation speed (slower speed)
    );
    
    // Opacity animation for fade-in and fade-out
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Slide animation for text (slide in from left to right)
    _slideAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0), // Start from the left (off-screen)
      end: Offset.zero, // End at the original position (on-screen)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Navigate to the main screen after n seconds
    Future.delayed(Duration(seconds: 8), () {
      setState(() {
        _isAnimationCompleted = true; // Mark the animation as completed
      });
      Navigator.pushReplacementNamed(context, '/dashboard');
    });

    // Start the animation when the splash screen is displayed
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // Lottie background animation
          Positioned.fill(
            child: Lottie.asset(
              'assets/images/Splash_Screen_Background.json', // The path to your Lottie background file
              fit: BoxFit.cover,
              repeat: true, // Loop the background animation
            ),
          ),
          Center(
            child: FutureBuilder<String>(
              future: _loadSplashScreenData(), // Load the Splash JSON data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading indicator while fetching data
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading splash screen data'));
                }
                if (!snapshot.hasData || snapshot.data == '') {
                  return Center(child: Text('Splash screen data is empty or not available.'));
                }

                final splashData = snapshot.data ?? 'Splash Screen'; // Placeholder for Splash content
                return FadeTransition(
                  opacity: _opacityAnimation, // Apply the fade-in effect
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display the Lottie animation from the JSON file
                      Lottie.asset(
                        'assets/images/Splash_Screen.json', // The path to your Lottie JSON file
                        controller: _controller, // Assign the controller
                        width: 480, // Adjust size as needed
                        height: 400, // Adjust size as needed
                        fit: BoxFit.fill, // Control the fit of the animation
                        onLoaded: (composition) {
                          _controller.forward(); // Start the animation once the composition is loaded
                        },
                      ),
                      SizedBox(height: 30),
                      // Sliding text animation
                      SlideTransition(
                        position: _slideAnimation, // Use the sliding animation for the text
                        child: Text(
                          splashData,
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Chocolate Covered Raindrops', // Font similar to Edwardian Script ITC
                            color: Colors.black, // Set text color
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3), // Shallow shadow color
                                blurRadius: 5,
                                offset: Offset(2, 2), // Position of the shadow
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _loadSplashScreenData() async {
    try {
      // Load JSON data from the asset file
      final String jsonString = await rootBundle.loadString('assets/images/Splash_Screen.json'); // Correct path
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return jsonData['message'] ?? 'Welcome to Pawradise'; // Fallback message
    } catch (e) {
      print("Error loading splash screen data: $e");
      return 'Error loading splash screen data'; // Provide fallback error message
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller when the screen is destroyed
    super.dispose();
  }
}

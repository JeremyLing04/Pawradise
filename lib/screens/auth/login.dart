// screens/auth/login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  // Login method
  void _login() async {
    print('🔐 Login button pressed');
    
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    print('✅ Form validation passed');

    setState(() => _isLoading = true);
    print('🔄 Loading started');
    
    try {
      print('📧 Attempting sign in with: ${_emailController.text}');
      
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      print('✅ AuthService signIn completed, user: ${user != null}');
      
      if (user != null) {
        print('🎯 User is not null, navigating to dashboard...');
        print('👤 User UID: ${user.uid}');
        print('📧 User email: ${user.email}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        print('❌ AuthService returned null user');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      
      // Handle potential plugin bug
      if (e.toString().contains("List<Object?>") && e.toString().contains("PigeonUserDetails")) {
        print('⚠️ Plugin bug detected, checking if user was actually signed in');
        await Future.delayed(Duration(seconds: 2));
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('✅ User was actually signed in: ${currentUser.uid}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }
      }
      
      // Show error messages under relevant fields
      final errorMessage = e.toString();
      if (errorMessage.contains('No account found with this email') || 
          errorMessage.contains('user-not-found')) {
        setState(() {
          _emailError = errorMessage;
        });
      } else if (errorMessage.contains('Incorrect password') || 
                errorMessage.contains('wrong-password')) {
        setState(() {
          _passwordError = errorMessage;
        });
      } else if (errorMessage.contains('invalid-credential') || 
                errorMessage.contains('The supplied auth credential')) {
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          setState(() {
            _emailError = 'Please enter a valid email address';
            _passwordError = null;
          });
        } else {
          setState(() {
            _emailError = null;
            _passwordError = 'Incorrect password';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      print('🏁 Login process completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/login sign up background.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha((0.3 * 255).round()),
                BlendMode.darken,
              ),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDogHeader(), // Custom header
                      SizedBox(height: 40),

                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sign in to continue to Pawradise',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 24),

                                // Email input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email, color: AppColors.primary),
                                        labelStyle: TextStyle(color: AppColors.accent),
                                        filled: true,
                                        fillColor: AppColors.secondary.withAlpha(40),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                        errorBorder: _emailError != null
                                            ? OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.red, width: 1),
                                              )
                                            : null,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your email';
                                        if (!value.contains('@')) return 'Please enter a valid email';
                                        return null;
                                      },
                                      onChanged: (_) {
                                        if (_emailError != null) setState(() => _emailError = null);
                                      },
                                    ),
                                    if (_emailError != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4, left: 12),
                                        child: Text(
                                          _emailError!,
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Password input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        labelStyle: TextStyle(color: AppColors.accent),
                                        filled: true,
                                        fillColor: AppColors.secondary.withAlpha(40),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                        errorBorder: _passwordError != null
                                            ? OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.red, width: 1),
                                              )
                                            : null,
                                      ),
                                      obscureText: _obscurePassword,
                                      keyboardType: TextInputType.visiblePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your password';
                                        if (value.length < 6) return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                      onChanged: (_) {
                                        if (_passwordError != null) setState(() => _passwordError = null);
                                      },
                                    ),
                                    if (_passwordError != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4, left: 12),
                                        child: Text(
                                          _passwordError!,
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Sign up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                    ),
                                    GestureDetector(
                                      onTap: _isLoading ? null : () => Navigator.pushNamed(context, '/register'),
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom header widget
  Widget _buildDogHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.pets, size: 60, color: AppColors.primary),
        ),
        SizedBox(height: 16),
        Text(
          'Pawradise',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            shadows: [Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        Text(
          'Your Pet\'s Paradise',
          style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

//screens/auth/login.dart
import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _fakeLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  // void _Login() async {
  //   setState(() => _isLoading = true);
    
  //   try {
  //     final user = await _authService.signIn(
  //       _emailController.text.trim(),
  //       _passwordController.text.trim(),
  //     );
      
  //     if (user != null) {
  //       Navigator.pushReplacementNamed(context, '/dashboard');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString())),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // ✅ 点击空白收起键盘
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
              child: SingleChildScrollView( // ✅ 外层加滚动
                padding: EdgeInsets.all(24),
                child: ConstrainedBox( // ✅ 限制宽度，避免太宽
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDogHeader(),
                      SizedBox(height: 40),

                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
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

                              // Email 输入框
                              TextField(
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
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 16),

                              // 密码输入框
                              TextField(
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
                                ),
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.visiblePassword,
                              ),
                              SizedBox(height: 24),

                              // 登录按钮
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _fakeLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text('Sign In', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              SizedBox(height: 16),

                              // 注册按钮
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: Text(
                                  "Don't have an account? Sign Up",
                                  style: TextStyle(color: AppColors.accent),
                                ),
                              ),
                            ],
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

  //CUSTOM HEADER
  Widget _buildDogHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pets,
            size: 60,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Pawradise',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        Text(
          'Your Pet\'s Paradise',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

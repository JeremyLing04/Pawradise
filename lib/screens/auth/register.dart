import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart'; 

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📋 Form data:');
      print('📋 Username: ${_usernameController.text}');
      print('📋 Email: ${_emailController.text}');
      print('📋 Password: ${_passwordController.text}');
      
      final user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (user != null) {
        _showSuccessAndNavigate();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('REGISTRATION ERROR: $e');
      print('ERROR TYPE: ${e.runtimeType}');
      
      // 专门处理 Firebase 插件的已知 bug
      if (_isFirebasePigeonBug(e)) {
        _handlePigeonBug();
      } else {
        // 显示原始错误信息（其他正常错误）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _isFirebasePigeonBug(dynamic error) {
    final errorString = error.toString();
    return errorString.contains("List<Object?>") && 
          errorString.contains("PigeonUserDetails");
  }

  // 处理 Firebase 插件 bug - 使用正确的 Future.delayed
  void _handlePigeonBug() async {
    print('Handling known Firebase plugin bug...');
    
    // 正确的用法：Future.delayed
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.email == _emailController.text.trim()) {
        print('User was actually created successfully: ${currentUser.uid}');
        _showSuccessAndNavigate();
      } else {
        _showRetryPrompt();
      }
    } catch (checkError) {
      print('Error checking user status: $checkError');
      _showRetryPrompt();
    }
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registration successful! Welcome to Pawradise!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showRetryPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registration Status'),
        content: Text('Your account may have been created. Please try logging in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 背景层
            Container(
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
            ),

            // 返回按钮层 - 固定在左上角
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // 主要内容层 - 居中显示
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Card(
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
                              // Logo or icon
                              Icon(
                                Icons.pets,
                                size: 50,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 16),
                              
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Join the Pawradise community',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 24),
                              
                              // 用户名输入框
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                                  labelStyle: TextStyle(color: AppColors.accent),
                                  filled: true,
                                  fillColor: AppColors.secondary.withAlpha(40),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // 邮箱输入框
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
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // 密码输入框
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
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // 确认密码输入框
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  labelStyle: TextStyle(color: AppColors.accent),
                                  filled: true,
                                  fillColor: AppColors.secondary.withAlpha(40),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              
                              // 注册按钮
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
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
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text('Create Account', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // 登录链接
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  GestureDetector(
                                    onTap: _isLoading ? null : () => Navigator.pop(context),
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
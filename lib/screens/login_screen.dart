import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/api/notification_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:impact_app/screens/home_screen.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/utils/form_validator.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final Logger _logger = Logger();
  final String _tag = 'LoginScreen';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseApiUrl + ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      setState(() => _isLoading = false);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save user data and token
        User user = User.fromJson(data['data']);
        String token = data['token'];
        
        _logger.d(_tag, 'Login successful for user: ${user.name}, ID: ${user.id}');
        
        // Save session data
        await SessionManager().saveSession(user, token);
        
        // Register device token with user ID
        _registerDeviceToken();
        
        // Navigate to home
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        // Handle login error
        final errorData = json.decode(response.body);
        _showErrorSnackBar(errorData['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      setState(() => _isLoading = false);
      _showErrorSnackBar('Terjadi kesalahan: $e');
      _logger.e(_tag, 'Login error: $e');
    }
  }
  
  Future<void> _registerDeviceToken() async {
    try {
      _logger.d(_tag, 'Registering device token after login...');
      
      // Gunakan NotificationApiService untuk register token
      final success = await NotificationApiService().registerDeviceToken();
      
      if (success) {
        _logger.d(_tag, 'Device token registered successfully');
      } else {
        _logger.e(_tag, 'Failed to register device token');
      }
    } catch (e) {
      _logger.e(_tag, 'Error registering device token: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png', height: 100),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Masuk',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Silahkan masuk ke akun anda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidator.validateEmail,
                  decoration: InputDecoration(
                    hintText: 'Masukkan email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kata Sandi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: FormValidator.validatePassword,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password screen
                    },
                    child: const Text(
                      'Lupa Kata Sandi',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
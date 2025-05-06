import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager {
  // Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserData = 'userData';
  static const String keyToken = 'token';
  
  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  
  factory SessionManager() {
    return _instance;
  }
  
  SessionManager._internal();
  
  // Save user session after login
  Future<void> saveSession(User user, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyUserData, jsonEncode(user.toJson()));
    await prefs.setString(keyToken, token);
  }
  
  // Get logged in status
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }
  
  // Get token
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString(keyUserData);
    if (userData != null) {
      Map<String, dynamic> userMap = jsonDecode(userData);
      return User.fromJson(userMap);
    }
    return null;
  }
  
  // Update user data
  Future<void> updateUserData(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserData, jsonEncode(user.toJson()));
  }
  
  // Logout and clear session
  Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.remove(keyUserData);
    await prefs.remove(keyToken);
  }
}
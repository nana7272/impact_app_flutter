import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:impact_app/services/notification_service.dart';
import '../models/notification_model.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../utils/logger.dart';
import '../utils/session_manager.dart';

class NotificationApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'NotificationApiService';
  
  // Mendapatkan FCM token dan mendaftarkannya
  Future<bool> registerDeviceToken() async {
    try {
      // Dapatkan user info terlebih dahulu
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found or user ID is null');
        return false;
      }
      
      // Dapatkan FCM token
      String? token = await FirebaseService().getToken();
      
      if (token == null) {
        _logger.e(_tag, 'Failed to get FCM token');
        throw Exception('Failed to get FCM token');
      }
      
      // Tentukan jenis device
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      
      // Log untuk debugging
      _logger.d(_tag, 'Registering device token: $token');
      _logger.d(_tag, 'Device type: $deviceType');
      _logger.d(_tag, 'User ID: ${user.idLogin}');
      
      // Register token ke server
      final response = await _client.post(
        ApiConstants.deviceToken,
        {
          'device_token': token,
          'device_type': deviceType,
          'user_id': user.idLogin, // Tambahkan user_id ke payload
        },
      );
      
      _logger.d(_tag, 'Register device token response: $response');
      
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error registering device token: $e');
      return false;
    }
  }
  
  // Mendapatkan daftar notifikasi
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _client.get(ApiConstants.notifications);
      
      if (response['data'] != null) {
        return AppNotification.fromJsonList(response['data']);
      }
      
      return [];
    } catch (e) {
      _logger.e(_tag, 'Error getting notifications: $e');
      return [];
    }
  }
  
  // Menandai notifikasi sebagai terbaca
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client.put(
        '${ApiConstants.notifications}/$notificationId/read',
        {},
      );
      
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error marking notification as read: $e');
      return false;
    }
  }
}
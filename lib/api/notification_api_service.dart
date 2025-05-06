import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../services/notification_service.dart';

class NotificationApiService {
  final ApiClient _client = ApiClient();
  
  // Mendapatkan FCM token dan mendaftarkannya
  Future<bool> registerDeviceToken() async {
    try {
      // Dapatkan FCM token
      String? token = await NotificationService().getToken();
      
      if (token == null) {
        throw Exception('Failed to get FCM token');
      }
      
      // Tentukan jenis device
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      
      // Register token ke server
      await _client.post(
        ApiConstants.deviceToken,
        {
          'device_token': token,
          'device_type': deviceType,
        },
      );
      
      return true;
    } catch (e) {
      print('Error registering device token: $e');
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
      print('Error getting notifications: $e');
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
      print('Error marking notification as read: $e');
      return false;
    }
  }
}
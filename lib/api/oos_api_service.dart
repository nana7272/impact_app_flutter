// File: lib/api/oos_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/oos_model.dart';

class OOSApiService {
  final ApiClient _client = ApiClient();
  
  // Submit data Out of Stock
  Future<bool> submitOOSData(String storeId, String visitId, List<OOSItemModel> items) async {
    try {
      // Persiapkan data untuk dikirim
      List<Map<String, dynamic>> itemsData = [];
      for (var item in items) {
        itemsData.add(item.toJson());
      }
      
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': itemsData,
      };
      
      // Kirim data ke server
      final response = await _client.post(
        ApiConstants.outOfStock,
        data,
      );
      
      return response['success'] ?? false;
    } catch (e) {
      print('Error submitting OOS data: $e');
      return false;
    }
  }
  
  // Simpan data OOS secara lokal
  Future<bool> saveOOSOffline(String storeId, String visitId, List<OOSItemModel> items) async {
    try {
      // Persiapkan data untuk disimpan lokal
      List<Map<String, dynamic>> itemsData = [];
      for (var item in items) {
        itemsData.add(item.toJson());
      }
      
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': itemsData,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      
      // Contoh penyimpanan lokal (implementasi nyata akan menggunakan SQLite/Hive)
      // dbHelper.insertOOSData(data);
      
      return true;
    } catch (e) {
      print('Error saving OOS data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data OOS offline
  Future<bool> syncOfflineOOSData() async {
    try {
      // Implementasi sinkronisasi data offline
      // Contoh:
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflineOOSData();
      // 
      // for (var data in offlineData) {
      //   List<OOSItemModel> items = [];
      //   for (var item in data['items']) {
      //     items.add(OOSItemModel.fromJson(item));
      //   }
      //   
      //   bool success = await submitOOSData(data['store_id'], data['visit_id'], items);
      //   
      //   if (success) {
      //     dbHelper.markOOSDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline OOS data: $e');
      return false;
    }
  }
  
  // Get history OOS submissions
  Future<List<OOSSubmission>> getOOSHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.outOfStock}/history?store_id=$storeId');
      
      List<OOSSubmission> history = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          history.add(OOSSubmission.fromJson(item));
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting OOS history: $e');
      return [];
    }
  }
}
// File: lib/api/posm_api_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/store_model.dart';

class POSMApiService {
  final ApiClient _client = ApiClient();
  
  // Submit POSM data ke server
  Future<bool> submitPOSMData(String storeId, String visitId, List<Map<String, dynamic>> posmItems, List<File> images) async {
    try {
      // Submit data dasar terlebih dahulu
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items_count': posmItems.length.toString(),
      };
      
      // Kirim data dasar ke server
      final response = await _client.post(
        ApiConstants.posm,
        data,
      );
      
      if (response['success'] != true) {
        throw Exception('Failed to submit POSM data');
      }
      
      // Get POSM submission ID
      final String posmSubmissionId = response['data']['id'];
      
      // Submit item satu per satu dengan gambar
      for (int i = 0; i < posmItems.length; i++) {
        final item = posmItems[i];
        final File imageFile = images[i];
        
        // Upload item POSM dengan foto
        await _client.uploadFile(
          '${ApiConstants.posm}/$posmSubmissionId/items',
          imageFile,
          'image',
          data: {
            'posm_type': item['type'],
            'posm_status': item['status'],
            'posm_installed': item['installed'],
            'posm_note': item['note'],
            'index': i.toString(),
          },
        );
      }
      
      return true;
    } catch (e) {
      print('Error submitting POSM data: $e');
      return false;
    }
  }
  
  // Simpan POSM data secara offline
  Future<bool> savePOSMOffline(String storeId, String visitId, List<Map<String, dynamic>> posmItems, List<String> imagePaths) async {
    try {
      // Implementasi penyimpanan lokal menggunakan SQLite atau Hive
      // Ini merupakan contoh saja, implementasi nyata akan bergantung pada solusi database lokal yang Anda gunakan
      
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
        'items': posmItems,
        'image_paths': imagePaths,
      };
      
      // Simpan ke database lokal
      // Contoh pseudocode:
      // dbHelper.insertPOSMData(json.encode(data));
      
      return true;
    } catch (e) {
      print('Error saving POSM data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data POSM offline ke server
  Future<bool> syncOfflinePOSMData() async {
    try {
      // Implementasi sinkronisasi data offline
      // Contoh pseudocode:
      // List<Map<String, dynamic>> offlineData = dbHelper.getPendingPOSMData();
      // 
      // for (var data in offlineData) {
      //   // Submit data ke server
      //   bool success = await submitPOSMData(...);
      //   
      //   // Jika berhasil, hapus dari database lokal atau tandai sebagai synced
      //   if (success) {
      //     dbHelper.markPOSMDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline POSM data: $e');
      return false;
    }
  }
  
  // Get history POSM submissions
  Future<List<Map<String, dynamic>>> getPOSMHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.posm}/history?store_id=$storeId');
      
      List<Map<String, dynamic>> history = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          history.add(Map<String, dynamic>.from(item));
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting POSM history: $e');
      return [];
    }
  }
}
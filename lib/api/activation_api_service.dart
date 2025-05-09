// File: lib/api/activation_api_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/activation_model.dart';

class ActivationApiService {
  final ApiClient _client = ApiClient();
  
  // Submit aktivasi data ke server
  Future<bool> submitActivationData(String storeId, String visitId, List<ActivationItem> items, List<File> images) async {
    try {
      // Persiapkan data dasar
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items_count': items.length.toString(),
      };
      
      // Kirim data dasar ke server
      final response = await _client.post(
        ApiConstants.activation,
        data,
      );
      
      if (response['success'] != true) {
        throw Exception('Failed to submit activation data');
      }
      
      // Get submission ID
      final String activationSubmissionId = response['data']['id'];
      
      // Submit item satu per satu dengan gambar
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final File imageFile = images[i];
        
        // Upload item aktivasi dengan foto
        await _client.uploadFile(
          '${ApiConstants.activation}/$activationSubmissionId/items',
          imageFile,
          'image',
          data: {
            'program': item.program,
            'periode': item.periode,
            'keterangan': item.keterangan,
            'index': i.toString(),
          },
        );
      }
      
      return true;
    } catch (e) {
      print('Error submitting activation data: $e');
      return false;
    }
  }
  
  // Simpan aktivasi data secara offline
  Future<bool> saveActivationOffline(String storeId, String visitId, List<ActivationItem> items, List<String> imagePaths) async {
    try {
      // Persiapkan data untuk penyimpanan lokal
      List<Map<String, dynamic>> itemsData = [];
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        itemsData.add({
          'program': item.program,
          'periode': item.periode,
          'keterangan': item.keterangan,
          'image_path': imagePaths[i],
        });
      }
      
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': itemsData,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      
      // Simpan ke database lokal (contoh implementasi)
      // Actual implementation would use SQLite or Hive
      // dbHelper.insertActivationData(json.encode(data));
      
      return true;
    } catch (e) {
      print('Error saving activation data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data offline ke server
  Future<bool> syncOfflineActivationData() async {
    try {
      // Get offline data
      // Contoh implementasi:
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflineActivationData();
      // 
      // for (var data in offlineData) {
      //   // Extract items
      //   List<ActivationItem> items = [];
      //   List<File> images = [];
      //   
      //   for (var itemData in data['items']) {
      //     items.add(ActivationItem(
      //       program: itemData['program'],
      //       periode: itemData['periode'],
      //       keterangan: itemData['keterangan'],
      //     ));
      //     
      //     images.add(File(itemData['image_path']));
      //   }
      //   
      //   // Submit to server
      //   bool success = await submitActivationData(
      //     data['store_id'],
      //     data['visit_id'],
      //     items,
      //     images,
      //   );
      //   
      //   // Mark as synced if successful
      //   if (success) {
      //     dbHelper.markActivationDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline activation data: $e');
      return false;
    }
  }
  
  // Get history aktivasi
  Future<List<ActivationSubmission>> getActivationHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.activation}/history?store_id=$storeId');
      
      List<ActivationSubmission> history = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          history.add(ActivationSubmission.fromJson(item));
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting activation history: $e');
      return [];
    }
  }
}
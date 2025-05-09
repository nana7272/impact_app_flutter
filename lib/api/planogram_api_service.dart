// File: lib/api/planogram_api_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/planogram_model.dart';

class PlanogramApiService {
  final ApiClient _client = ApiClient();
  
  // Submit planogram data ke server
  Future<bool> submitPlanogramData(String storeId, String visitId, List<PlanogramItemModel> items, List<File> beforeImages, List<File> afterImages) async {
    try {
      // Persiapkan data dasar
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items_count': items.length.toString(),
      };
      
      // Kirim data dasar ke server
      final response = await _client.post(
        ApiConstants.planogram,
        data,
      );
      
      if (response['success'] != true) {
        throw Exception('Failed to submit planogram data');
      }
      
      // Get submission ID
      final String planogramSubmissionId = response['data']['id'];
      
      // Submit item satu per satu dengan gambar
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final File beforeImageFile = beforeImages[i];
        final File afterImageFile = afterImages[i];
        
        // Upload data item
        final itemResponse = await _client.post(
          '${ApiConstants.planogram}/$planogramSubmissionId/items',
          {
            'display_type': item.displayType,
            'display_issue': item.displayIssue,
            'desc_before': item.descBefore,
            'desc_after': item.descAfter,
            'index': i.toString(),
          },
        );
        
        final String itemId = itemResponse['data']['id'];
        
        // Upload before image
        await _client.uploadFile(
          '${ApiConstants.planogram}/$planogramSubmissionId/items/$itemId/before',
          beforeImageFile,
          'image',
          data: {
            'desc': item.descBefore,
          },
        );
        
        // Upload after image
        await _client.uploadFile(
          '${ApiConstants.planogram}/$planogramSubmissionId/items/$itemId/after',
          afterImageFile,
          'image',
          data: {
            'desc': item.descAfter,
          },
        );
      }
      
      return true;
    } catch (e) {
      print('Error submitting planogram data: $e');
      return false;
    }
  }
  
  // Simpan planogram data secara offline
  Future<bool> savePlanogramOffline(String storeId, String visitId, List<PlanogramItemModel> items, List<String> beforeImagePaths, List<String> afterImagePaths) async {
    try {
      // Persiapkan data untuk penyimpanan lokal
      List<Map<String, dynamic>> itemsData = [];
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        itemsData.add({
          'display_type': item.displayType,
          'display_issue': item.displayIssue,
          'desc_before': item.descBefore,
          'desc_after': item.descAfter,
          'before_image_path': beforeImagePaths[i],
          'after_image_path': afterImagePaths[i],
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
      // dbHelper.insertPlanogramData(json.encode(data));
      
      return true;
    } catch (e) {
      print('Error saving planogram data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data offline ke server
  Future<bool> syncOfflinePlanogramData() async {
    try {
      // Get offline data
      // Contoh implementasi:
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflinePlanogramData();
      // 
      // for (var data in offlineData) {
      //   // Extract items
      //   List<PlanogramItemModel> items = [];
      //   List<File> beforeImages = [];
      //   List<File> afterImages = [];
      //   
      //   for (var itemData in data['items']) {
      //     items.add(PlanogramItemModel(
      //       displayType: itemData['display_type'],
      //       displayIssue: itemData['display_issue'],
      //       descBefore: itemData['desc_before'],
      //       descAfter: itemData['desc_after'],
      //     ));
      //     
      //     beforeImages.add(File(itemData['before_image_path']));
      //     afterImages.add(File(itemData['after_image_path']));
      //   }
      //   
      //   // Submit to server
      //   bool success = await submitPlanogramData(
      //     data['store_id'],
      //     data['visit_id'],
      //     items,
      //     beforeImages,
      //     afterImages,
      //   );
      //   
      //   // Mark as synced if successful
      //   if (success) {
      //     dbHelper.markPlanogramDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline planogram data: $e');
      return false;
    }
  }
  
  // Get history planogram
  Future<List<PlanogramSubmission>> getPlanogramHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.planogram}/history?store_id=$storeId');
      
      List<PlanogramSubmission> history = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          history.add(PlanogramSubmission.fromJson(item));
        }
      }
      
      return history;
    } catch (e) {
      print('Error getting planogram history: $e');
      return [];
    }
  }
}
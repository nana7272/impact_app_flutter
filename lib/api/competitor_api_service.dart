// File: lib/api/competitor_api_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/product_model.dart';
import '../models/competitor_model.dart';

class CompetitorApiService {
  final ApiClient _client = ApiClient();
  
  // Pencarian produk
  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _client.get('${ApiConstants.searchProducts}?keyword=$keyword');
      
      List<Product> products = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          products.add(Product.fromJson(item));
        }
      }
      
      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
  
  // Submit data competitor ke server
  Future<bool> submitCompetitor(
    String storeId, 
    String visitId, 
    List<Map<String, dynamic>> items,
    List<File?> ownImages,
    List<File?> competitorImages,
  ) async {
    try {
      // Create submission data
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'items_count': items.length.toString(),
      };
      
      // Submit basic data
      final response = await _client.post(
        ApiConstants.competitor,
        data,
      );
      
      if (response['success'] != true) {
        throw Exception('Failed to submit competitor data');
      }
      
      // Get submission ID
      final String submissionId = response['data']['id'];
      
      // Submit each competitor item
      for (int i = 0; i < items.length; i++) {
        final itemData = items[i];
        
        // Submit item data
        final itemResponse = await _client.post(
          '${ApiConstants.competitor}/$submissionId/items',
          itemData,
        );
        
        final String itemId = itemResponse['data']['id'];
        
        // Upload own product image if available
        if (ownImages[i] != null) {
          await _client.uploadFile(
            '${ApiConstants.competitor}/$submissionId/items/$itemId/own-image',
            ownImages[i]!,
            'image',
          );
        }
        
        // Upload competitor product image if available
        if (competitorImages[i] != null) {
          await _client.uploadFile(
            '${ApiConstants.competitor}/$submissionId/items/$itemId/competitor-image',
            competitorImages[i]!,
            'image',
          );
        }
      }
      
      return true;
    } catch (e) {
      print('Error submitting competitor data: $e');
      return false;
    }
  }
  
  // Simpan data competitor secara offline
  Future<bool> saveCompetitorOffline(
    String storeId, 
    String visitId, 
    List<Map<String, dynamic>> items,
    List<String> ownImagePaths,
    List<String> competitorImagePaths,
  ) async {
    try {
      // Create data for local storage
      final Map<String, dynamic> storageData = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': items,
        'own_image_paths': ownImagePaths,
        'competitor_image_paths': competitorImagePaths,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      
      // Save to local database (example implementation)
      // In reality, you would use SQLite or Hive here
      // dbHelper.insertCompetitorData(json.encode(storageData));
      
      return true;
    } catch (e) {
      print('Error saving competitor data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data offline ke server
  Future<bool> syncOfflineCompetitorData() async {
    try {
      // Get data from local storage
      // Example implementation:
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflineCompetitorData();
      // 
      // for (var data in offlineData) {
      //   List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(data['items']);
      //   List<String> ownImagePaths = List<String>.from(data['own_image_paths']);
      //   List<String> competitorImagePaths = List<String>.from(data['competitor_image_paths']);
      //   
      //   // Convert paths to File objects
      //   List<File?> ownImages = [];
      //   List<File?> competitorImages = [];
      //   
      //   for (var path in ownImagePaths) {
      //     ownImages.add(path.isNotEmpty ? File(path) : null);
      //   }
      //   
      //   for (var path in competitorImagePaths) {
      //     competitorImages.add(path.isNotEmpty ? File(path) : null);
      //   }
      //   
      //   // Submit to server
      //   bool success = await submitCompetitor(
      //     data['store_id'],
      //     data['visit_id'],
      //     items,
      //     ownImages,
      //     competitorImages,
      //   );
      //   
      //   // Mark as synced if successful
      //   if (success) {
      //     dbHelper.markCompetitorDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline competitor data: $e');
      return false;
    }
  }
  
  // Get history competitor submissions
  Future<List<CompetitorSubmission>> getCompetitorHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.competitor}/history?store_id=$storeId');
      
      List<CompetitorSubmission> submissions = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          submissions.add(CompetitorSubmission.fromJson(item));
        }
      }
      
      return submissions;
    } catch (e) {
      print('Error getting competitor history: $e');
      return [];
    }
  }
}
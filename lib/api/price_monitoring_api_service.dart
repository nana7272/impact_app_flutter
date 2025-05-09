// File: lib/api/price_monitoring_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/product_model.dart';
import '../models/price_monitoring_model.dart';

class PriceMonitoringApiService {
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
  
  // Submit data price monitoring
  Future<bool> submitPriceMonitoring(String storeId, String visitId, List<PriceItem> items) async {
    try {
      // Persiapkan data untuk submission
      List<Map<String, dynamic>> itemsData = [];
      
      for (var item in items) {
        itemsData.add({
          'product_id': item.productId,
          'product_name': item.productName,
          'normal_price': item.normalPrice,
          'promo_price': item.promoPrice,
          'notes': item.notes,
        });
      }
      
      final submissionData = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': itemsData,
      };
      
      // Kirim data ke server
      final response = await _client.post(
        ApiConstants.priceMonitoring,
        submissionData,
      );
      
      return response['success'] ?? false;
    } catch (e) {
      print('Error submitting price monitoring data: $e');
      return false;
    }
  }
  
  // Simpan data secara offline
  Future<bool> savePriceMonitoringOffline(String storeId, String visitId, List<PriceItem> items) async {
    try {
      // Persiapkan data untuk penyimpanan lokal
      List<Map<String, dynamic>> itemsData = [];
      
      for (var item in items) {
        itemsData.add({
          'product_id': item.productId,
          'product_name': item.productName,
          'normal_price': item.normalPrice,
          'promo_price': item.promoPrice,
          'notes': item.notes,
        });
      }
      
      final storageData = {
        'store_id': storeId,
        'visit_id': visitId,
        'items': itemsData,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      
      // Save to local storage (contoh implementasi)
      // Implementasi nyata akan menggunakan SQLite atau Hive
      // dbHelper.insertPriceMonitoringData(json.encode(storageData));
      
      return true;
    } catch (e) {
      print('Error saving price monitoring data offline: $e');
      return false;
    }
  }
  
  // Sinkronisasi data offline ke server
  Future<bool> syncOfflinePriceMonitoringData() async {
    try {
      // Get data from local storage
      // Contoh implementasi:
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflinePriceMonitoringData();
      // 
      // for (var data in offlineData) {
      //   List<PriceItem> items = [];
      //   
      //   for (var item in data['items']) {
      //     items.add(PriceItem(
      //       productId: item['product_id'],
      //       productName: item['product_name'],
      //       normalPrice: item['normal_price'],
      //       promoPrice: item['promo_price'],
      //       notes: item['notes'],
      //     ));
      //   }
      //   
      //   bool success = await submitPriceMonitoring(
      //     data['store_id'],
      //     data['visit_id'],
      //     items,
      //   );
      //   
      //   if (success) {
      //     // Mark as synced
      //     dbHelper.markPriceMonitoringDataSynced(data['id']);
      //   }
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline price monitoring data: $e');
      return false;
    }
  }
  
  // Get history price monitoring submissions
  Future<List<PriceMonitoringSubmission>> getPriceMonitoringHistory(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.priceMonitoring}/history?store_id=$storeId');
      
      List<PriceMonitoringSubmission> submissions = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          submissions.add(PriceMonitoringSubmission.fromJson(item));
        }
      }
      
      return submissions;
    } catch (e) {
      print('Error getting price monitoring history: $e');
      return [];
    }
  }
}
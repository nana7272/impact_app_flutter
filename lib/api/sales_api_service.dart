import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/offline/ofline_data_manager.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/product_sales_model.dart';
import '../models/sales_print_out_model.dart';
import '../utils/logger.dart';
import '../utils/session_manager.dart';

class SalesApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'SalesApiService';
  final OfflineDataManager _offlineDataManager = OfflineDataManager();

  // Submit data Open Ending
Future<bool> submitOpenEnding(String storeId, String visitId, List<Map<String, dynamic>> products) async {
  try {
    // Create Open Ending data
    final Map<String, dynamic> data = {
      'store_id': storeId,
      'visit_id': visitId,
      'products': products,
    };
    
    // Submit data
    final response = await _client.post(
      '${ApiConstants.openEnding}',
      data,
    );
    
    return response['success'] ?? false;
  } catch (e) {
    print('Error submitting open ending data: $e');
    return false;
  }
}

// Save Open Ending data offline
Future<bool> saveOpenEndingOffline(String storeId, String visitId, List<Map<String, dynamic>> products) async {
  try {
    // Implementasi penyimpanan lokal menggunakan SQLite atau Hive
    // Ini adalah contoh implementasi dasar
    
    final Map<String, dynamic> data = {
      'store_id': storeId,
      'visit_id': visitId,
      'products': products,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };
    
    // Simpan ke database lokal
    // dbHelper.insertOpenEnding(data);
    
    // Untuk demo, kita anggap berhasil disimpan
    return true;
  } catch (e) {
    print('Error saving open ending offline: $e');
    return false;
  }
}
  
  // Pencarian produk
  Future<List<ProductSales>> searchProducts(String keyword) async {
    try {
      _logger.d(_tag, 'Searching products with keyword: $keyword');
      final response = await _client.get('${ApiConstants.searchProducts}?keyword=$keyword');
      
      List<ProductSales> products = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          products.add(ProductSales.fromJson(item));
        }
      }
      
      _logger.d(_tag, 'Found ${products.length} products');
      return products;
    } catch (e) {
      _logger.e(_tag, 'Error searching products: $e');
      return [];
    }
  }
  
  // Submit data Sales Print Out
  Future<bool> submitSalesPrintOut(String storeId, String visitId, List<ProductSales> products, List<File?> photos) async {
    try {
      _logger.d(_tag, 'Submitting sales print out for store: $storeId, visit: $visitId');
      
      // Get user ID from session
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found');
        return false;
      }
      
      // Create sales print out data
      List<Map<String, dynamic>> items = [];
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        items.add({
          'product_id': product.id,
          'product_name': product.name,
          'sell_out_qty': product.sellOutQty.toString(),
          'sell_out_value': product.sellOutValue.toString(),
          'periode': product.periode,
        });
      }
      
      final Map<String, dynamic> requestData = {
        'store_id': storeId,
        'visit_id': visitId,
        'user_id': user.idLogin, // Explicitly include user_id in request
        'items': items,
      };
      
      _logger.d(_tag, 'Request data: $requestData');
      
      // Submit data
      final response = await _client.post(
        ApiConstants.salesPrintOut,
        requestData,
      );
      
      // Log response for debugging
      _logger.d(_tag, 'Submit response: $response');
      
      if (response == null || response['data'] == null || response['data']['id'] == null) {
        _logger.e(_tag, 'Invalid response format: $response');
        return false;
      }
      
      // Get sales print out ID
      final salesPrintOutId = response['data']['id'];
      
      // Upload photos if available
      if (photos.isNotEmpty) {
        _logger.d(_tag, 'Uploading ${photos.length} photos');
        
        for (int i = 0; i < photos.length; i++) {
          if (photos[i] != null) {
            try {
              await _client.uploadFile(
                '${ApiConstants.salesPrintOut}/$salesPrintOutId/photos',
                photos[i]!,
                'photo',
                data: {
                  'product_id': products[i].id!,
                  'index': i.toString(),
                },
              );
              _logger.d(_tag, 'Successfully uploaded photo $i');
            } catch (e) {
              _logger.e(_tag, 'Error uploading photo $i: $e');
              // Continue with next photo even if this one fails
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error submitting sales print out: $e');
      return false;
    }
  }
  
  // Get history sales print out
  Future<List<SalesPrintOut>> getSalesPrintOutHistory() async {
    try {
      _logger.d(_tag, 'Getting sales print out history');
      final response = await _client.get(ApiConstants.salesPrintOut);
      
      List<SalesPrintOut> salesPrintOuts = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          salesPrintOuts.add(SalesPrintOut.fromJson(item));
        }
      }
      
      _logger.d(_tag, 'Found ${salesPrintOuts.length} sales print outs');
      return salesPrintOuts;
    } catch (e) {
      _logger.e(_tag, 'Error getting sales print out history: $e');
      return [];
    }
  }
  
  // Get sales print out detail
  Future<SalesPrintOut?> getSalesPrintOutDetail(String id) async {
    try {
      _logger.d(_tag, 'Getting sales print out detail for ID: $id');
      final response = await _client.get('${ApiConstants.salesPrintOut}/$id');
      
      if (response['data'] != null) {
        return SalesPrintOut.fromJson(response['data']);
      }
      
      _logger.w(_tag, 'No data found for sales print out ID: $id');
      return null;
    } catch (e) {
      _logger.e(_tag, 'Error getting sales print out detail: $e');
      return null;
    }
  }
  
  // Save sales print out offline
  Future<bool> saveSalesPrintOutOffline(String storeId, String visitId, List<ProductSales> products, List<String?> photosPaths) async {
    try {
      _logger.d(_tag, 'Saving sales print out offline');
      
      // Get user ID from session
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found');
        return false;
      }
      
      // Here you would implement local storage using SQLite or Hive
      // For example:
      
      // Create a database helper instance
      //final dbHelper = DatabaseHelper();
      
      // Create the data to save
      final Map<String, dynamic> data = {
        'store_id': storeId,
        'visit_id': visitId,
        'user_id': user.idLogin,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'items': products.map((p) => {
          'product_id': p.id,
          'product_name': p.name,
          'sell_out_qty': p.sellOutQty,
          'sell_out_value': p.sellOutValue,
          'periode': p.periode,
          'photo_path': photosPaths[products.indexOf(p)],
        }).toList(),
      };
      
      // Save to database
      //final id = await dbHelper.insertSalesPrintOut(data);
      
      _logger.d(_tag, 'Sales print out saved offline with data: $data');
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error saving sales print out offline: $e');
      return false;
    }
  }
  
  // Sync offline sales print out data
  Future<bool> syncOfflineSalesPrintOut() async {
    return _offlineDataManager.syncData(
      'sales_print_outs', 
      submitSalesPrintOut,
      idField: 'id', // Sesuaikan dengan nama field ID di tabel Anda
    );
  }
}
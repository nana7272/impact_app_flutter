import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/product_sales_model.dart';
import '../models/sales_print_out_model.dart';

class SalesApiService {
  final ApiClient _client = ApiClient();
  
  // Pencarian produk
  Future<List<ProductSales>> searchProducts(String keyword) async {
    try {
      final response = await _client.get('${ApiConstants.searchProducts}?keyword=$keyword');
      
      List<ProductSales> products = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          products.add(ProductSales.fromJson(item));
        }
      }
      
      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
  
  // Submit data Sales Print Out
  Future<bool> submitSalesPrintOut(String storeId, String visitId, List<ProductSales> products, List<File?> photos) async {
    try {
      // Create sales print out data
      List<SalesPrintOutItem> items = [];
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        items.add(SalesPrintOutItem(
          productId: product.id,
          productName: product.name,
          sellOutQty: product.sellOutQty,
          sellOutValue: product.sellOutValue,
          periode: product.periode,
        ));
      }
      
      final salesPrintOut = SalesPrintOut(
        storeId: storeId,
        visitId: visitId,
        items: items,
      );
      
      // Submit data
      final response = await _client.post(
        ApiConstants.salesPrintOut,
        salesPrintOut.toJson(),
      );
      
      // Get sales print out ID
      final salesPrintOutId = response['data']['id'];
      
      // Upload photos if available
      if (photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          if (photos[i] != null) {
            await _client.uploadFile(
              '${ApiConstants.salesPrintOut}/$salesPrintOutId/photos',
              photos[i]!,
              'photo',
              data: {
                'product_id': products[i].id!,
                'index': i.toString(),
              },
            );
          }
        }
      }
      
      return true;
    } catch (e) {
      print('Error submitting sales print out: $e');
      return false;
    }
  }
  
  // Get history sales print out
  Future<List<SalesPrintOut>> getSalesPrintOutHistory() async {
    try {
      final response = await _client.get(ApiConstants.salesPrintOut);
      
      List<SalesPrintOut> salesPrintOuts = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          salesPrintOuts.add(SalesPrintOut.fromJson(item));
        }
      }
      
      return salesPrintOuts;
    } catch (e) {
      print('Error getting sales print out history: $e');
      return [];
    }
  }
  
  // Get sales print out detail
  Future<SalesPrintOut?> getSalesPrintOutDetail(String id) async {
    try {
      final response = await _client.get('${ApiConstants.salesPrintOut}/$id');
      
      return SalesPrintOut.fromJson(response['data']);
    } catch (e) {
      print('Error getting sales print out detail: $e');
      return null;
    }
  }
  
  // Save sales print out offline
  Future<bool> saveSalesPrintOutOffline(String storeId, String visitId, List<ProductSales> products, List<String?> photosPaths) async {
    try {
      // Implementasi penyimpanan lokal menggunakan SQLite atau Hive
      // Ini hanyalah contoh implementasi yang akan perlu disesuaikan
      // berdasarkan database lokal yang Anda gunakan
      
      // Simpan ke database lokal
      // dbHelper.insertSalesPrintOut(storeId, visitId, products, photosPaths);
      
      return true;
    } catch (e) {
      print('Error saving sales print out offline: $e');
      return false;
    }
  }
  
  // Sync offline sales print out data
  Future<bool> syncOfflineSalesPrintOut() async {
    try {
      // Implementasi sinkronisasi data offline
      // Ini hanyalah contoh implementasi yang akan perlu disesuaikan
      
      // Ambil data offline dari database lokal
      // List<Map<String, dynamic>> offlineData = dbHelper.getOfflineSalesPrintOuts();
      
      // if (offlineData.isEmpty) {
      //   return true;
      // }
      
      // for (var data in offlineData) {
      //   // Submit data ke server
      //   // ...
      
      //   // Jika berhasil, hapus dari database lokal
      //   // dbHelper.deleteSalesPrintOut(data['id']);
      // }
      
      return true;
    } catch (e) {
      print('Error syncing offline sales print out: $e');
      return false;
    }
  }
}
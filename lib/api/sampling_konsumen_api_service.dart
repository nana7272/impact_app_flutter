import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/database/db_helper.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/sampling_konsumen_model.dart';
import '../utils/connectivity_utils.dart';

class SamplingKonsumenApiService {
  final ApiClient _client = ApiClient();
  final DBHelper _dbHelper = DBHelper(); // Asumsi ini adalah helper database lokal Anda
  
  // Mencari produk untuk sampling
  Future<List<ProdukSampling>> searchProduk(String keyword) async {
    try {
      final response = await _client.get('${ApiConstants.produkSampling}?keyword=$keyword');
      
      List<ProdukSampling> products = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          products.add(ProdukSampling.fromJson(item));
        }
      }
      
      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
  
  // Mendapatkan daftar produk sampling
  Future<List<ProdukSampling>> getProdukSampling() async {
    try {
      final response = await _client.get(ApiConstants.produkSampling);
      
      List<ProdukSampling> products = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          products.add(ProdukSampling.fromJson(item));
        }
      }
      
      return products;
    } catch (e) {
      print('Error getting produk sampling: $e');
      return [];
    }
  }
  
  // Submit data sampling konsumen secara online (ke server)
  Future<bool> submitSamplingKonsumen(SamplingKonsumen data) async {
    try {
      // Check internet connection
      bool isConnected = await ConnectivityUtils.checkInternetConnection();
      
      if (!isConnected) {
        throw Exception('No internet connection');
      }
      
      final response = await _client.post(
        ApiConstants.samplingKonsumen,
        data.toJson(),
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error submitting sampling konsumen: $e');
      throw e;
    }
  }
  
  // Menyimpan data sampling konsumen secara lokal (offline)
  Future<bool> saveSamplingKonsumenOffline(SamplingKonsumen data) async {
    try {
      // Simpan ke database lokal (asumsi menggunakan SQLite atau Hive)
      await _dbHelper.insertSamplingKonsumen(data.toJson());
      return true;
    } catch (e) {
      print('Error saving sampling konsumen offline: $e');
      return false;
    }
  }
  
  // Mendapatkan daftar data sampling konsumen yang belum disinkronkan
  Future<List<SamplingKonsumen>> getPendingSamplingKonsumen() async {
    try {
      // Get dari database lokal
      List<Map<String, dynamic>> offlineData = await _dbHelper.getPendingSamplingKonsumen();
      
      List<SamplingKonsumen> samplings = [];
      for (var data in offlineData) {
        samplings.add(SamplingKonsumen.fromJson(data));
      }
      
      return samplings;
    } catch (e) {
      print('Error getting pending sampling konsumen: $e');
      return [];
    }
  }
  
  // Sinkronisasi data sampling konsumen yang tersimpan offline
  Future<bool> syncPendingSamplingKonsumen() async {
    try {
      // Check internet connection
      bool isConnected = await ConnectivityUtils.checkInternetConnection();
      
      if (!isConnected) {
        return false;
      }
      
      // Get data offline
      List<SamplingKonsumen> pendingData = await getPendingSamplingKonsumen();
      
      if (pendingData.isEmpty) {
        return true;
      }
      
      bool hasError = false;
      
      for (var data in pendingData) {
        try {
          // Submit data ke server
          bool success = await submitSamplingKonsumen(data);
          
          if (success) {
            // Hapus dari database lokal atau tandai sebagai tersinkronisasi
            await _dbHelper.markSamplingKonsumenAsSynced(data.id!);
          } else {
            hasError = true;
          }
        } catch (e) {
          print('Error syncing sampling konsumen data: $e');
          hasError = true;
        }
      }
      
      return !hasError;
    } catch (e) {
      print('Error syncing sampling konsumen: $e');
      return false;
    }
  }
  
  // Mendapatkan riwayat sampling konsumen
  Future<List<SamplingKonsumen>> getSamplingKonsumenHistory() async {
    try {
      final response = await _client.get(ApiConstants.samplingKonsumen);
      
      List<SamplingKonsumen> samplings = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          samplings.add(SamplingKonsumen.fromJson(item));
        }
      }
      
      return samplings;
    } catch (e) {
      print('Error getting sampling konsumen history: $e');
      return [];
    }
  }
}
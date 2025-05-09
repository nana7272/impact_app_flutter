// lib/api/promo_audit_api_service.dart
// Update metode submitPromoAudit untuk konversi Map<String, dynamic> ke Map<String, String>

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:impact_app/database/db_helper.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/promo_audit_model.dart';
import '../models/store_model.dart';
import '../utils/connectivity_utils.dart';

class PromoAuditApiService {
  final ApiClient _client = ApiClient();
  final DBHelper _dbHelper = DBHelper();
  
  // Submit data promo audit secara online (ke server)
  Future<bool> submitPromoAudit(PromoAudit data, File? photo) async {
    try {
      // Check internet connection
      bool isConnected = await ConnectivityUtils.checkInternetConnection();
      
      if (!isConnected) {
        throw Exception('No internet connection');
      }
      
      // Jika tanpa foto
      if (photo == null) {
        final response = await _client.post(
          ApiConstants.promoAudit,
          data.toJson(),
        );
        
        return response['success'] == true;
      } else {
        // Convert Map<String, dynamic> to Map<String, String>
        Map<String, String> stringData = {};
        data.toJson().forEach((key, value) {
          stringData[key] = value.toString();
        });
        
        // Dengan foto, gunakan uploadFile
        final response = await _client.uploadFile(
          ApiConstants.promoAudit,
          photo,
          'photo',
          data: stringData,
        );
        
        return response['success'] == true;
      }
    } catch (e) {
      print('Error submitting promo audit: $e');
      throw e;
    }
  }
  
  // Menyimpan foto secara lokal
  Future<String> _savePhotoLocally(File photo, String id) async {
    try {
      // Buat direktori untuk menyimpan foto jika belum ada
      final Directory appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/promo_audit_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }
      
      // Generate nama file dan simpan foto
      final fileName = '${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${photoDir.path}/$fileName';
      
      // Salin file ke path lokal
      await photo.copy(localPath);
      return localPath;
    } catch (e) {
      print('Error saving photo locally: $e');
      throw e;
    }
  }
  
  // Menyimpan data promo audit secara lokal (offline)
  Future<bool> savePromoAuditOffline(PromoAudit data, File? photo) async {
    try {
      // Generate ID lokal jika belum ada
      String id = data.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}';
      
      // Simpan foto secara lokal jika ada
      String? localPhotoPath;
      if (photo != null) {
        localPhotoPath = await _savePhotoLocally(photo, id);
      }
      
      // Update model dengan ID dan path foto
      final updatedData = data.copyWith(
        id: id,
        photoUrl: localPhotoPath,
        createdAt: DateTime.now().toIso8601String(),
        isSynced: false,
      );
      
      // Simpan ke database lokal
      await _dbHelper.insertPromoAudit(updatedData.toJson());
      return true;
    } catch (e) {
      print('Error saving promo audit offline: $e');
      return false;
    }
  }
  
  // Mendapatkan data promo audit untuk toko tertentu
  Future<PromoAudit?> getPromoAuditByStore(String storeId, String visitId) async {
    try {
      // Cek data online
      bool isConnected = await ConnectivityUtils.checkInternetConnection();
      
      if (isConnected) {
        try {
          final response = await _client.get('${ApiConstants.promoAudit}?store_id=$storeId&visit_id=$visitId');
          
          if (response['data'] != null) {
            return PromoAudit.fromJson(response['data']);
          }
        } catch (e) {
          print('Error getting online promo audit: $e');
        }
      }
      
      // Jika tidak online atau gagal mendapatkan data online, coba ambil dari lokal
      Map<String, dynamic>? localData = await _dbHelper.getPromoAuditByStore(storeId, visitId);
      
      if (localData != null) {
        return PromoAudit.fromJson(localData);
      }
      
      return null;
    } catch (e) {
      print('Error getting promo audit: $e');
      return null;
    }
  }
  
  // Mendapatkan daftar data promo audit yang belum disinkronkan
  Future<List<PromoAudit>> getPendingPromoAudits() async {
    try {
      // Get dari database lokal
      List<Map<String, dynamic>> offlineData = await _dbHelper.getPendingPromoAudits();
      
      List<PromoAudit> promoAudits = [];
      for (var data in offlineData) {
        promoAudits.add(PromoAudit.fromJson(data));
      }
      
      return promoAudits;
    } catch (e) {
      print('Error getting pending promo audits: $e');
      return [];
    }
  }
  
  // Sinkronisasi data promo audit yang tersimpan offline
  Future<bool> syncPendingPromoAudits() async {
    try {
      // Check internet connection
      bool isConnected = await ConnectivityUtils.checkInternetConnection();
      
      if (!isConnected) {
        return false;
      }
      
      // Get data offline
      List<PromoAudit> pendingData = await getPendingPromoAudits();
      
      if (pendingData.isEmpty) {
        return true;
      }
      
      bool hasError = false;
      
      for (var data in pendingData) {
        try {
          // Check if there's a local photo
          File? photoFile;
          if (data.photoUrl != null && data.photoUrl!.startsWith('/')) {
            photoFile = File(data.photoUrl!);
            if (!await photoFile.exists()) {
              photoFile = null;
            }
          }
          
          // Submit data ke server
          bool success = await submitPromoAudit(data, photoFile);
          
          if (success) {
            // Hapus dari database lokal atau tandai sebagai tersinkronisasi
            await _dbHelper.markPromoAuditAsSynced(data.id!);
          } else {
            hasError = true;
          }
        } catch (e) {
          print('Error syncing promo audit data: $e');
          hasError = true;
        }
      }
      
      return !hasError;
    } catch (e) {
      print('Error syncing promo audits: $e');
      return false;
    }
  }

  // Mendapatkan riwayat promo audit
  Future<List<PromoAudit>> getPromoAuditHistory() async {
    try {
      final response = await _client.get(ApiConstants.promoAudit);
      
      List<PromoAudit> promoAudits = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          promoAudits.add(PromoAudit.fromJson(item));
        }
      }
      
      return promoAudits;
    } catch (e) {
      print('Error getting promo audit history: $e');
      return [];
    }
  }
}
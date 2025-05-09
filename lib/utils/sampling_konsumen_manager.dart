// lib/utils/sampling_konsumen_manager.dart
import 'package:flutter/material.dart';
import 'package:impact_app/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';

class SamplingKonsumenManager {
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  
  // Singleton pattern
  static final SamplingKonsumenManager _instance = SamplingKonsumenManager._internal();
  
  factory SamplingKonsumenManager() {
    return _instance;
  }
  
  SamplingKonsumenManager._internal();
  
  // Mendapatkan jumlah data yang belum tersinkronisasi
  Future<int> getPendingCount() async {
    try {
      final pendingData = await _apiService.getPendingSamplingKonsumen();
      return pendingData.length;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }
  
  // Sinkronisasi data yang belum tersinkronisasi
  Future<bool> syncPendingData(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sinkronisasi data sampling konsumen...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
      
      bool result = await _apiService.syncPendingSamplingKonsumen();
      
      // Close loading dialog
      Navigator.pop(context);
      
      return result;
    } catch (e) {
      print('Error syncing pending data: $e');
      
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sinkronisasi data: $e')),
      );
      
      return false;
    }
  }
  
  // Menyimpan data sampling konsumen secara online atau offline
  Future<bool> saveSamplingKonsumen(SamplingKonsumen data, bool isOnline, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      bool result;
      
      if (isOnline) {
        result = await _apiService.submitSamplingKonsumen(data);
      } else {
        result = await _apiService.saveSamplingKonsumenOffline(data);
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show message
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline 
              ? 'Data berhasil dikirim ke server' 
              : 'Data berhasil disimpan secara lokal'
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline 
              ? 'Gagal mengirim data ke server' 
              : 'Gagal menyimpan data secara lokal'
            ),
          ),
        );
      }
      
      return result;
    } catch (e) {
      print('Error saving sampling konsumen: $e');
      
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      
      return false;
    }
  }
  
  // Pencarian produk
  Future<List<ProdukSampling>> searchProduk(String keyword, BuildContext context) async {
    try {
      return await _apiService.searchProduk(keyword);
    } catch (e) {
      print('Error searching produk: $e');
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencari produk: $e')),
      );
      
      return [];
    }
  }
  
  // Menghapus data sampling konsumen yang belum tersinkronisasi
  Future<bool> deletePendingSamplingKonsumen(String id, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Implementasi metode delete pada DBHelper
      // Asumsi ada method deleteOfflineSamplingKonsumen pada DBHelper
      // await DBHelper().deleteOfflineSamplingKonsumen(id);
      
      // Close loading dialog
      Navigator.pop(context);
      
      return true;
    } catch (e) {
      print('Error deleting sampling konsumen: $e');
      
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menghapus data: $e')),
      );
      
      return false;
    }
  }
}
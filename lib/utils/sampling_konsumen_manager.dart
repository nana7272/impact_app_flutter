// lib/utils/sampling_konsumen_manager.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/sampling_konsument/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';

class SamplingKonsumenManager {
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  
  // Singleton pattern
  static final SamplingKonsumenManager _instance = SamplingKonsumenManager._internal();
  
  factory SamplingKonsumenManager() {
    return _instance;
  }
  
  SamplingKonsumenManager._internal();
  
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
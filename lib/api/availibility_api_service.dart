import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/product_model.dart';
import '../utils/logger.dart';

class AvailabilityApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  static const String _tag = 'AvailabilityApiService';

  // Get availability data for a store
  Future<List<Map<String, dynamic>>> getAvailabilityData(String storeId) async {
    try {
      final response = await _client.get('${ApiConstants.availability}?store_id=$storeId');
      
      List<Map<String, dynamic>> availabilityData = [];
      if (response['data'] != null) {
        for (var item in response['data']) {
          availabilityData.add(Map<String, dynamic>.from(item));
        }
      }
      
      return availabilityData;
    } catch (e) {
      _logger.e(_tag, 'Error getting availability data: $e');
      return [];
    }
  }
  
  // Submit availability data
  Future<bool> submitAvailabilityData({
    required String storeId,
    required String visitId,
    required List<Map<String, dynamic>> productsData,
    required Map<String, String?> imagePaths,
  }) async {
    try {
      // Create data for API request
      Map<String, dynamic> requestData = {
        'store_id': storeId,
        'visit_id': visitId,
        'products': productsData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Submit basic data
      final response = await _client.post(
        ApiConstants.availability,
        requestData,
      );
      
      // Get availability ID from response
      final availabilityId = response['data']['id'];
      
      // Upload images if available
      for (var productId in imagePaths.keys) {
        if (imagePaths['${productId}_before'] != null) {
          await _uploadImage(
            availabilityId,
            productId,
            File(imagePaths['${productId}_before']!),
            'before',
          );
        }
        
        if (imagePaths['${productId}_after'] != null) {
          await _uploadImage(
            availabilityId,
            productId,
            File(imagePaths['${productId}_after']!),
            'after',
          );
        }
      }
      
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error submitting availability data: $e');
      return false;
    }
  }
  
  // Upload image
  Future<void> _uploadImage(
    String availabilityId,
    String productId,
    File imageFile,
    String imageType,
  ) async {
    try {
      await _client.uploadFile(
        '${ApiConstants.availability}/$availabilityId/images',
        imageFile,
        'image',
        data: {
          'product_id': productId,
          'image_type': imageType,
        },
      );
    } catch (e) {
      _logger.e(_tag, 'Error uploading image: $e');
    }
  }
}
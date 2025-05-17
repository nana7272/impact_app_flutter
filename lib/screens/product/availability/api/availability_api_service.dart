// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/availability/api/availability_api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/product/availability/model/availability_offline_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';

class AvailabilityApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String _tag = "AvailabilityApiService";
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AvailabilityApiService() {
    _dio.options.baseUrl = ApiConstants.baseApiUrl;
  }

  Future<bool> saveAvailabilityDataOffline(Map<String, dynamic> headerData, List<Map<String, dynamic>> itemsData) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Insert header
        headerData['is_synced'] = 0;
        headerData['tgl_submission'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
        int headerId = await txn.insert('availability_headers', headerData);

        // Insert items
        for (var item in itemsData) {
          item['header_id'] = headerId;
          await txn.insert('availability_items', item);
        }
      });
      _logger.d(_tag, "Successfully saved availability data (header & ${itemsData.length} items) offline.");
      return true;
    } catch (e) {
      _logger.e(_tag, "Error saving availability data offline: $e");
      return false;
    }
  }

  Future<bool> submitAvailabilityDataOnline({
    required String idUser,
    required String idOutlet,
    File? imageBeforeFile,
    File? imageAfterFile,
    required List<Map<String, dynamic>> items, // List of {'id_product': val, 'stock_gudang': val, ...}
  }) async {
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null) {
        _logger.e(_tag, "User not logged in or token is missing.");
        throw Exception("User not logged in or token is missing.");
      }

      var formData = FormData.fromMap({
        'id_user': idUser,
        'id_outlet': idOutlet,
      });

      if (imageBeforeFile != null && await imageBeforeFile.exists()) {
        formData.files.add(MapEntry(
          'imgae_before_file', // Sesuai API spec
          await MultipartFile.fromFile(imageBeforeFile.path, filename: imageBeforeFile.path.split('/').last),
        ));
      }
      if (imageAfterFile != null && await imageAfterFile.exists()) {
        formData.files.add(MapEntry(
          'image_after_file', // Sesuai API spec
          await MultipartFile.fromFile(imageAfterFile.path, filename: imageAfterFile.path.split('/').last),
        ));
      }

      for (int i = 0; i < items.length; i++) {
        items[i].forEach((key, value) {
          formData.fields.add(MapEntry('items[$i][$key]', value.toString()));
        });
      }
      
      _logger.d(_tag, "Sending availability data online. Fields: ${formData.fields.length}, Files: ${formData.files.length}");

      final response = await _dio.post(
        '/api/availabilities',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      _logger.d(_tag, "Online availability submission response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _logger.e(_tag, "Online availability submission failed with status: ${response.statusCode}");
        throw Exception("Gagal mengirim data: Server error ${response.statusCode}");
      }
    } on DioError catch (e) {
      _logger.e(_tag, "DioError submitting availability data online: ${e.message}");
      if (e.response != null) {
        _logger.e(_tag, "DioError response data: ${e.response?.data}");
        throw Exception("Gagal mengirim data: ${e.response?.data['message'] ?? e.message}");
      }
      throw Exception("Gagal mengirim data: ${e.message}");
    } catch (e) {
      _logger.e(_tag, "Error submitting availability data online: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  Future<List<OfflineAvailabilityHeader>> getOfflineAvailabilityForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedAvailabilityHeadersWithItems();
      if (rawData.isEmpty) {
        return [];
      }
      final headers = rawData.map((map) => OfflineAvailabilityHeader.fromMap(map)).toList();
      _logger.d(_tag, "Fetched ${headers.length} offline availability headers with items.");
      return headers;
    } catch (e) {
      _logger.e(_tag, "Error fetching offline availability entries: $e");
      throw Exception("Gagal memuat data offline: $e");
    }
  }

  Future<bool> syncOfflineAvailabilityData() async {
    _logger.d(_tag, "Starting sync of offline availability data.");
    List<OfflineAvailabilityHeader> unsyncedHeaders = await getOfflineAvailabilityForDisplay();

    if (unsyncedHeaders.isEmpty) {
      _logger.d(_tag, "No offline availability data to sync.");
      return true;
    }

    bool allSyncsSuccessful = true;

    for (var header in unsyncedHeaders) {
      try {
        File? beforeImg = header.imageBeforePath != null && header.imageBeforePath!.isNotEmpty ? File(header.imageBeforePath!) : null;
        File? afterImg = header.imageAfterPath != null && header.imageAfterPath!.isNotEmpty ? File(header.imageAfterPath!) : null;

        List<Map<String, dynamic>> itemsPayload = header.items.map((item) => {
          'id_product': item.idProduct,
          'stock_gudang': item.stockGudang,
          'stock_display': item.stockDisplay,
          'total_stock': item.totalStock,
        }).toList();

        _logger.d(_tag, "Attempting to sync availability header ID: ${header.dbId} with ${itemsPayload.length} items.");
        bool success = await submitAvailabilityDataOnline(
          idUser: header.idUser,
          idOutlet: header.idOutlet,
          imageBeforeFile: beforeImg,
          imageAfterFile: afterImg,
          items: itemsPayload,
        );

        if (success) {
          await _dbHelper.deleteAvailabilityHeaderAndItems(header.dbId);
          _logger.d(_tag, "Successfully synced and deleted availability header ID: ${header.dbId}.");
        } else {
          _logger.w(_tag, "Failed to sync availability header ID: ${header.dbId}. It will remain in local DB.");
          allSyncsSuccessful = false;
        }
      } catch (e) {
        _logger.e(_tag, "Error syncing availability header ID ${header.dbId}: $e. It will remain in local DB.");
        allSyncsSuccessful = false;
      }
    }
    _logger.d(_tag, "Availability sync process finished. Overall success: $allSyncsSuccessful");
    return allSyncsSuccessful;
  }
}

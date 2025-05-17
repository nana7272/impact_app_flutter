// lib/screens/product/competitor/api/competitor_api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/product/competitor/model/competitor_offline_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class CompetitorApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String _tag = "CompetitorApiService";
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  CompetitorApiService() {
    _dio.options.baseUrl = ApiConstants.baseApiUrl;
    // Tambahkan interceptor jika diperlukan untuk logging atau error handling
  }

  Future<bool> saveCompetitorDataOffline(List<Map<String, dynamic>> promoItems) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        for (var item in promoItems) {
          await txn.insert('promo_activity_entries', item);
        }
      });
      _logger.d(_tag, "Successfully saved ${promoItems.length} competitor items offline.");
      return true;
    } catch (e) {
      _logger.e(_tag, "Error saving competitor data offline: $e");
      return false;
    }
  }

  Future<bool> submitCompetitorDataOnline(
      List<Map<String, dynamic>> promoItemsData, 
      List<File?> images) async {
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null ) {
        _logger.e(_tag, "User not logged in or token is missing.");
        throw Exception("User not logged in or token is missing.");
      }

      var formData = FormData();
      for (int i = 0; i < promoItemsData.length; i++) {
        var item = promoItemsData[i];
        item.forEach((key, value) {
          formData.fields.add(MapEntry('promo_items[$i][$key]', value.toString()));
        });
        
        if (images.length > i && images[i] != null) {
          // formData.files.add(MapEntry(
          //   'promo_items[$i][image_file]',
          //   await MultipartFile.fromFile(images[i]!.path, filename: images[i]!.path.split('/').last),
          // ));

          File imageFile = images[i]!;
          // Check if path is not empty and file exists before attempting to upload
          if (imageFile.path.isNotEmpty && await imageFile.exists()) {
            formData.files.add(MapEntry(
              'image_files[$i]',
              await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
            ));
          } else {
            //_logger.w(_tag, "Image file for promo_items[$i] path is empty ('${imageFile.path}') or file does not exist. Skipping file upload for this item.");
            // No file is added if path is empty or file doesn't exist, fulfilling the "not mandatory" requirement.
            formData.files.add(MapEntry(
                'image_files[$i]',
                await MultipartFile.fromBytes([], filename: ''),
              ));
          }

        } else {
           // _logger.w(_tag, "Image file for promo_items[$i] path is empty ('${imageFile.path}') or file does not exist. Skipping file upload for this item.");
            // No file is added if path is empty or file doesn't exist, fulfilling the "not mandatory" requirement.
          formData.files.add(MapEntry(
            'image_files[$i]',
            await MultipartFile.fromBytes([], filename: ''),
          ));
        }
      }
      
      _logger.d(_tag, "Sending competitor data online. Payload fields: ${formData.fields.length}, files: ${formData.files.length}");

      final response = await _dio.post(
        '/api/promo-activities/batch',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      _logger.d(_tag, "Online submission response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
         return true;
      } else {
        _logger.e(_tag, "Online submission failed with status: ${response.statusCode}");
        throw Exception("Gagal mengirim data: Server error ${response.statusCode}");
      }
    } on DioError catch (e) {
      _logger.e(_tag, "DioError submitting competitor data online: ${e.message}");
      if (e.response != null) {
        _logger.e(_tag, "DioError response data: ${e.response?.data}");
         throw Exception("Gagal mengirim data: ${e.response?.data['message'] ?? e.message}");
      }
      throw Exception("Gagal mengirim data: ${e.message}");
    } catch (e) {
      _logger.e(_tag, "Error submitting competitor data online: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  Future<List<OfflinePromoActivityGroup>> getOfflinePromoActivitiesForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedPromoActivityEntries();
      if (rawData.isEmpty) {
        return [];
      }

      Map<String, OfflinePromoActivityGroup> groups = {};

      for (var row in rawData) {
        String submissionGroupId = row['submission_group_id'] as String;
        if (!groups.containsKey(submissionGroupId)) {
          groups[submissionGroupId] = OfflinePromoActivityGroup(
            submissionGroupId: submissionGroupId,
            outletId: row['id_outlet'] as String,
            outletName: row['outlet_name'] as String? ?? 'Unknown Outlet',
            tglSubmission: row['tgl_submission'] as String,
            userId: row['id_user'] as String,
            principleId: row['id_principle'] as String,
            items: [],
          );
        }
        groups[submissionGroupId]!.items.add(OfflinePromoActivityItemDetail.fromMap(row));
      }
      _logger.d(_tag, "Fetched ${groups.values.length} offline promo activity groups.");
      return groups.values.toList();
    } catch (e) {
      _logger.e(_tag, "Error fetching offline promo activities: $e");
      throw Exception("Gagal memuat data offline: $e");
    }
  }

  Future<bool> syncOfflinePromoActivities() async {
    _logger.d(_tag, "Starting sync of offline promo activities.");
    List<Map<String, dynamic>> unsyncedEntries = await _dbHelper.getUnsyncedPromoActivityEntries();

    if (unsyncedEntries.isEmpty) {
      _logger.d(_tag, "No offline promo activities to sync.");
      return true; // No data to sync, consider it a success.
    }

    // Group entries by submission_group_id
    Map<String, List<Map<String, dynamic>>> groupedBySubmissionId = {};
    for (var entry in unsyncedEntries) {
      String groupId = entry['submission_group_id'] as String;
      groupedBySubmissionId.putIfAbsent(groupId, () => []).add(entry);
    }

    _logger.d(_tag, "Found ${groupedBySubmissionId.keys.length} groups of submissions to sync.");
    bool allSyncsSuccessful = true;

    for (var groupId in groupedBySubmissionId.keys) {
      List<Map<String, dynamic>> currentGroupEntries = groupedBySubmissionId[groupId]!;
      List<Map<String, dynamic>> promoItemsPayload = [];
      List<File?> imagesPayload = [];
      List<int> dbIdsToClear = [];

      for (var entry in currentGroupEntries) {
        promoItemsPayload.add({
          'nama_produk': entry['nama_produk'],
          'id_product': entry['id_product'],
          'id_user': entry['id_user'],
          'id_outlet': entry['id_outlet'],
          'id_principle': entry['id_principle'],
          'category_product': entry['category_product'],
          'harga_rbp': entry['harga_rbp'],
          'harga_cbp': entry['harga_cbp'],
          'harga_outlet': entry['harga_outlet'],
          'promo_type': entry['promo_type'],
          'mekanisme_promo': entry['mekanisme_promo'],
          'periode': entry['periode'],
          'tgl': entry['tgl_submission'], // API expects 'tgl'
        });
        
        if (entry['image_path'] != null && (entry['image_path'] as String).isNotEmpty) {
          File imgFile = File(entry['image_path'] as String);
          if (await imgFile.exists()) {
            imagesPayload.add(imgFile);
          } else {
            imagesPayload.add(null);
            _logger.w(_tag, "Image file not found for sync: ${entry['image_path']}");
          }
        } else {
          imagesPayload.add(null);
        }
        dbIdsToClear.add(entry['id'] as int);
      }

      try {
        _logger.d(_tag, "Attempting to sync group: $groupId with ${promoItemsPayload.length} items.");
        bool success = await submitCompetitorDataOnline(promoItemsPayload, imagesPayload);
        if (success) {
          _logger.d(_tag, "Successfully synced group: $groupId. Deleting from local DB.");
          await _dbHelper.deletePromoActivityEntriesByIds(dbIdsToClear);
        } else {
          _logger.w(_tag, "Failed to sync group: $groupId. It will remain in local DB.");
          allSyncsSuccessful = false;
        }
      } catch (e) {
        _logger.e(_tag, "Error syncing group $groupId: $e. It will remain in local DB.");
        allSyncsSuccessful = false;
      }
    }
    _logger.d(_tag, "Sync process finished. Overall success: $allSyncsSuccessful");
    return allSyncsSuccessful;
  }
}

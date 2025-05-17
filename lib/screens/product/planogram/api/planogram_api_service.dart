// lib/screens/product/planogram/api/planogram_api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/planogram/model/api_display_type_model.dart';
import 'package:impact_app/screens/product/planogram/model/planogram_offline_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';

class PlanogramApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String _tag = "PlanogramApiService";
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PlanogramApiService() {
    _dio.options.baseUrl = ApiConstants.baseApiUrl;
    // Tambahkan interceptor jika diperlukan
  }

  Future<List<ApiDisplayType>> fetchDisplayTypes(String idPrinciple) async {
    try {
      final response = await _dio.get('/api/dokumentasi-gambar/type/$idPrinciple');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => ApiDisplayType.fromJson(json)).toList();
      } else {
        _logger.e(_tag, "Failed to fetch display types: ${response.statusCode}");
        throw Exception('Failed to load display types');
      }
    } on DioError catch (e) {
      _logger.e(_tag, "DioError fetching display types: ${e.message}");
      throw Exception('Error fetching display types: ${e.message}');
    } catch (e) {
      _logger.e(_tag, "Error fetching display types: $e");
      throw Exception('Error fetching display types: $e');
    }
  }

  Future<List<String>> fetchDisplayIssues(String idPrinciple) async {
    try {
      final response = await _dio.get('/api/dokumentasi-gambar/issue/$idPrinciple');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => json['nama'] as String).toList();
      } else {
        _logger.e(_tag, "Failed to fetch display issues: ${response.statusCode}");
        throw Exception('Failed to load display issues');
      }
    } on DioError catch (e) {
      _logger.e(_tag, "DioError fetching display issues: ${e.message}");
      throw Exception('Error fetching display issues: ${e.message}');
    } catch (e) {
      _logger.e(_tag, "Error fetching display issues: $e");
      throw Exception('Error fetching display issues: $e');
    }
  }

  Future<bool> savePlanogramDataOffline(List<Map<String, dynamic>> planogramItems) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        for (var item in planogramItems) {
          await txn.insert('planogram_entries', item);
        }
      });
      _logger.d(_tag, "Successfully saved ${planogramItems.length} planogram items offline.");
      return true;
    } catch (e) {
      _logger.e(_tag, "Error saving planogram data offline: $e");
      return false;
    }
  }

  Future<bool> submitPlanogramDataOnline(
      List<Map<String, dynamic>> dokumentasiItemsData,
      List<File?> beforeImages,
      List<File?> afterImages) async {
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null ) {
        _logger.e(_tag, "User not logged in or token is missing.");
        throw Exception("User not logged in or token is missing.");
      }

      var formData = FormData();
      for (int i = 0; i < dokumentasiItemsData.length; i++) {
        var item = dokumentasiItemsData[i];
        item.forEach((key, value) {
          formData.fields.add(MapEntry('dokumentasi_items[$i][$key]', value.toString()));
        });

        if (beforeImages.length > i && beforeImages[i] != null) {
          File imageFile = beforeImages[i]!;
          if (imageFile.path.isNotEmpty && await imageFile.exists()) {
            formData.files.add(MapEntry(
              'image_files1[$i]', // Foto Before
              await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
            ));
          } else {
             _logger.w(_tag, "Before image for item $i is invalid or does not exist. Path: ${imageFile.path}");
             formData.files.add(MapEntry(
              'image_files1[$i]', // Foto Before
              await MultipartFile.fromBytes([], filename: ''),
            ));
          }
        } else {
          formData.files.add(MapEntry(
              'image_files1[$i]', // Foto Before
              await MultipartFile.fromBytes([], filename: ''),
            ));
        }
        if (afterImages.length > i && afterImages[i] != null) {
          File imageFile = afterImages[i]!;
          if (imageFile.path.isNotEmpty && await imageFile.exists()) {
            formData.files.add(MapEntry(
              'image_files2[$i]', // Foto After
              await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
            ));
          } else {
            _logger.w(_tag, "After image for item $i is invalid or does not exist. Path: ${imageFile.path}");
            formData.files.add(MapEntry(
              'image_files2[$i]', // Foto After
              await MultipartFile.fromBytes([], filename: ''),
            ));
          }
        } else {
          formData.files.add(MapEntry(
              'image_files2[$i]', // Foto After
              await MultipartFile.fromBytes([], filename: ''),
            ));
          
        }
      }

      _logger.d(_tag, "Sending planogram data online. Payload fields: ${formData.fields.length}, files: ${formData.files.length}");

      final response = await _dio.post(
        '/api/dokumentasi-gambar/batch',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      _logger.d(_tag, "Online planogram submission response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200 || response.statusCode == 201) {
       return true;
      } else {
        _logger.e(_tag, "Online planogram submission failed with status: ${response.statusCode}");
        throw Exception("Gagal mengirim data: Server error ${response.statusCode}");
      }
    } on DioError catch (e) {
      _logger.e(_tag, "DioError submitting planogram data online: ${e.message}");
      if (e.response != null) {
        _logger.e(_tag, "DioError response data: ${e.response?.data}");
        throw Exception("Gagal mengirim data: ${e.response?.data['message'] ?? e.message}");
      }
      throw Exception("Gagal mengirim data: ${e.message}");
    } catch (e) {
      _logger.e(_tag, "Error submitting planogram data online: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  Future<List<OfflinePlanogramGroup>> getOfflinePlanogramEntriesForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedPlanogramEntries();
      if (rawData.isEmpty) {
        return [];
      }

      Map<String, OfflinePlanogramGroup> groups = {};
      for (var row in rawData) {
        String submissionGroupId = row['submission_group_id'] as String;
        if (!groups.containsKey(submissionGroupId)) {
          groups[submissionGroupId] = OfflinePlanogramGroup(
            submissionGroupId: submissionGroupId,
            outletId: row['id_outlet'] as String,
            outletName: row['outlet_name'] as String? ?? 'Unknown Outlet',
            tglSubmission: row['tgl_submission'] as String,
            userId: row['id_user'] as String,
            items: [],
          );
        }
        groups[submissionGroupId]!.items.add(OfflinePlanogramItemDetail.fromMap(row));
      }
      _logger.d(_tag, "Fetched ${groups.values.length} offline planogram groups.");
      return groups.values.toList();
    } catch (e) {
      _logger.e(_tag, "Error fetching offline planogram entries: $e");
      throw Exception("Gagal memuat data offline: $e");
    }
  }

  Future<bool> syncOfflinePlanogramEntries() async {
    _logger.d(_tag, "Starting sync of offline planogram entries.");
    List<Map<String, dynamic>> unsyncedEntries = await _dbHelper.getUnsyncedPlanogramEntries();

    if (unsyncedEntries.isEmpty) {
      _logger.d(_tag, "No offline planogram entries to sync.");
      return true;
    }

    Map<String, List<Map<String, dynamic>>> groupedBySubmissionId = {};
    for (var entry in unsyncedEntries) {
      String groupId = entry['submission_group_id'] as String;
      groupedBySubmissionId.putIfAbsent(groupId, () => []).add(entry);
    }

    _logger.d(_tag, "Found ${groupedBySubmissionId.keys.length} groups of planogram submissions to sync.");
    bool allSyncsSuccessful = true;

    for (var groupId in groupedBySubmissionId.keys) {
      List<Map<String, dynamic>> currentGroupEntries = groupedBySubmissionId[groupId]!;
      List<Map<String, dynamic>> dokumentasiItemsPayload = [];
      List<File?> beforeImagesPayload = [];
      List<File?> afterImagesPayload = [];
      List<int> dbIdsToClear = [];

      for (var entry in currentGroupEntries) {
        dokumentasiItemsPayload.add({
          'id_user': entry['id_user'],
          'id_outlet': entry['id_outlet'],
          'outlet': entry['outlet_name'],
          'ket': entry['ket_before'],
          'tgl': entry['tgl_submission'],
          'type': entry['display_type'],
          'complain': entry['display_issue'],
          'ket2': entry['ket_after'],
        });

        if (entry['image_before_path'] != null && (entry['image_before_path'] as String).isNotEmpty) {
          File imgFile = File(entry['image_before_path'] as String);
          if (await imgFile.exists()) beforeImagesPayload.add(imgFile);
          else {
            beforeImagesPayload.add(null);
            _logger.w(_tag, "Before image file not found for sync: ${entry['image_before_path']}");
          }
        } else beforeImagesPayload.add(null);

        if (entry['image_after_path'] != null && (entry['image_after_path'] as String).isNotEmpty) {
          File imgFile = File(entry['image_after_path'] as String);
          if (await imgFile.exists()) afterImagesPayload.add(imgFile);
          else {
            afterImagesPayload.add(null);
            _logger.w(_tag, "After image file not found for sync: ${entry['image_after_path']}");
          }
        } else afterImagesPayload.add(null);
        
        dbIdsToClear.add(entry['id'] as int);
      }

      try {
        _logger.d(_tag, "Attempting to sync planogram group: $groupId with ${dokumentasiItemsPayload.length} items.");
        bool success = await submitPlanogramDataOnline(dokumentasiItemsPayload, beforeImagesPayload, afterImagesPayload);
        if (success) {
          _logger.d(_tag, "Successfully synced planogram group: $groupId. Deleting from local DB.");
          await _dbHelper.deletePlanogramEntriesByIds(dbIdsToClear);
        } else {
          _logger.w(_tag, "Failed to sync planogram group: $groupId. It will remain in local DB.");
          allSyncsSuccessful = false;
        }
      } catch (e) {
        _logger.e(_tag, "Error syncing planogram group $groupId: $e. It will remain in local DB.");
        allSyncsSuccessful = false;
      }
    }
    _logger.d(_tag, "Planogram sync process finished. Overall success: $allSyncsSuccessful");
    return allSyncsSuccessful;
  }
}

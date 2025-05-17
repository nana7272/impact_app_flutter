// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/sampling_konsument/api/sampling_konsumen_api_service.dart
import 'package:dio/dio.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/product/sampling_konsument/model/sampling_konsumen_offline_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';

class SamplingKonsumenApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String _tag = "SamplingKonsumenApiService";
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  SamplingKonsumenApiService() {
    _dio.options.baseUrl = ApiConstants.baseApiUrl;
    // Tambahkan interceptor jika diperlukan
  }

  // Method untuk mengirim data Sampling Konsumen secara online
  Future<bool> submitSamplingKonsumen(SamplingKonsumenModel data) async {
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null) {
        _logger.e(_tag, "User not logged in or token is missing for online submission.");
        throw Exception('User not authenticated or token is missing.');
      }

      _logger.d(_tag, "Attempting online submission for Sampling Konsumen: ${data.toJson()}");

      final response = await _dio.post(
        '/api/sampling-konsumen',
        data: data.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
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
      _logger.e(_tag, "DioError submitting sampling konsumen data online: ${e.message}");
      if (e.response != null) {
        _logger.e(_tag, "DioError response data: ${e.response?.data}");
        throw Exception("Gagal mengirim data: ${e.response?.data['message'] ?? e.message}");
      }
      throw Exception("Gagal mengirim data: ${e.message}");
    } catch (e) {
      _logger.e(_tag, "Error submitting sampling konsumen data online: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  // Method untuk menyimpan data Sampling Konsumen secara offline
  Future<bool> saveSamplingKonsumenOffline(Map<String, dynamic> data) async {
    try {
      await _dbHelper.insertSamplingKonsumenEntry(data);
      _logger.d(_tag, "Successfully saved sampling konsumen data offline.");
      return true;
    } catch (e) {
      _logger.e(_tag, "Error saving sampling konsumen data offline: $e");
      return false;
    }
  }

  // Method untuk mengambil data Sampling Konsumen yang belum disinkronkan untuk ditampilkan
  Future<List<OfflineSamplingKonsumenItem>> getOfflineSamplingKonsumenForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedSamplingKonsumenEntries();
      if (rawData.isEmpty) {
        return [];
      }
      final items = rawData.map((map) => OfflineSamplingKonsumenItem.fromMap(map)).toList();
      _logger.d(_tag, "Fetched ${items.length} offline sampling konsumen items.");
      return items;
    } catch (e) {
      _logger.e(_tag, "Error fetching offline sampling konsumen entries: $e");
      throw Exception("Gagal memuat data offline: $e");
    }
  }

  // Method untuk melakukan sinkronisasi data Sampling Konsumen offline ke server
  Future<bool> syncOfflineSamplingKonsumenData() async {
    _logger.d(_tag, "Starting sync of offline sampling konsumen data.");
    List<Map<String, dynamic>> unsyncedEntries = await _dbHelper.getUnsyncedSamplingKonsumenEntries();

    if (unsyncedEntries.isEmpty) {
      _logger.d(_tag, "No offline sampling konsumen data to sync.");
      return true; // Tidak ada data untuk disinkronkan, anggap sukses
    }

    bool allSyncsSuccessful = true;
    List<int> successfullySyncedIds = [];

    for (var entry in unsyncedEntries) {
      try {
        // Siapkan payload sesuai format API (POST JSON)
        // Perhatikan tipe data yang diharapkan API (int vs String)
        final apiPayload = SamplingKonsumenModel(
          nama: entry['nama_konsumen'] as String,
          alamat: entry['alamat_konsumen'] as String,
          noHp: entry['no_hp_konsumen'] as String,
          umur: entry['umur_konsumen'] as int, // API expects int
          email: entry['email_konsumen'] as String?,
          idOutlet: int.tryParse(entry['id_outlet'] as String? ?? '0') ?? 0, // API expects int
          sender: int.tryParse(entry['id_user'] as String? ?? '0') ?? 0, // API expects int
          idProduct: int.tryParse(entry['id_product_dibeli'] as String? ?? '0') ?? 0, // API expects int
          // id_product_prev bisa null di API, jadi parse jika tidak null
          idProductPrev: entry['id_product_sebelumnya'] != null ? int.tryParse(entry['id_product_sebelumnya'] as String) : null, // API expects int?
          qlt: entry['kuantitas'] as int, // API expects int
          keterangan: entry['keterangan'] as String?,
          // API body tidak mencantumkan 'tgl', jadi tidak disertakan dalam payload API
        );

        _logger.d(_tag, "Attempting to sync sampling konsumen item ID: ${entry['id']}");
        bool success = await submitSamplingKonsumen(apiPayload);
        if (success) {
          successfullySyncedIds.add(entry['id'] as int);
          _logger.d(_tag, "Successfully synced sampling konsumen item ID: ${entry['id']}.");
        } else {
          _logger.w(_tag, "Failed to sync sampling konsumen item ID: ${entry['id']}. It will remain in local DB.");
          allSyncsSuccessful = false;
        }
      } catch (e) {
        _logger.e(_tag, "Error syncing sampling konsumen item ID ${entry['id']}: $e. It will remain in local DB.");
        allSyncsSuccessful = false;
      }
    }

    // Hapus data yang berhasil disinkronkan dari DB lokal
    if (successfullySyncedIds.isNotEmpty) {
      await _dbHelper.deleteSamplingKonsumenEntriesByIds(successfullySyncedIds);
      _logger.d(_tag, "Deleted ${successfullySyncedIds.length} synced sampling konsumen items from local DB.");
    }

    _logger.d(_tag, "Sampling konsumen sync process finished. Overall success: $allSyncsSuccessful");
    return allSyncsSuccessful;
  }
}

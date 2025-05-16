// File BARU: /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/api/price_monitoring_api_service.dart
import 'package:collection/collection.dart';
import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/price_monitoring_model.dart';
import 'package:impact_app/screens/product/price_monitoring/model/price_monitoring_model.dart';
import 'package:impact_app/utils/logger.dart';

class PriceMonitoringApiService {
  final ApiClient _apiClient = ApiClient();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();
  final String _tag = "PriceMonitoringApiService";

  Future<bool> submitPriceMonitoringOnline(List<PriceMonitoringEntryModel> entries) async {
    if (entries.isEmpty) return true;

    List<Map<String, dynamic>> payload = entries.map((item) => item.toJsonApi()).toList();
    _logger.d(_tag, "Submitting Price Monitoring data: $payload");

    try {
      // Menggunakan ApiClient.post untuk mengirim JSON raw
      final response = await _apiClient.post(ApiConstants.priceMonitoringCreateMultiple, payload);
      _logger.d(_tag, "Price Monitoring API Response: $response");

      // Asumsi API mengembalikan respons sukses (misal status 200-299) jika berhasil
      // ApiClient._processResponse sudah menangani status code dan melempar exception jika error
      return true;

    } catch (e) {
      _logger.e(_tag, "Error submitting Price Monitoring online: $e");
      // ApiClient sudah melempar ApiException, kita bisa rethrow atau return false
      // Untuk kesederhanaan, kita return false di sini
      return false;
    }
  }

  Future<bool> savePriceMonitoringOffline(List<PriceMonitoringEntryModel> entries) async {
    if (entries.isEmpty) return true;
    int successCount = 0;
    try {
      for (var entry in entries) {
        await _dbHelper.insertPriceMonitoringEntry(entry.toMapForDb());
        successCount++;
      }
      _logger.d(_tag, "Saved $successCount price monitoring entries to local DB.");
      return successCount == entries.length;
    } catch (e) {
      _logger.e(_tag, "Error saving price monitoring offline: $e");
      return false;
    }
  }

  Future<List<OfflinePriceMonitoringGroup>> getOfflinePriceMonitoringForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedPriceMonitoringEntries();
      if (rawData.isEmpty) return [];

      final List<PriceMonitoringEntryModel> allEntries = rawData.map((map) => PriceMonitoringEntryModel.fromMapDb(map)).toList();

      // Kelompokkan berdasarkan outletName dan tgl
      var groupedByOutletAndDate = groupBy<PriceMonitoringEntryModel, String>(
        allEntries,
        (item) => '${item.outletName ?? 'Unknown Outlet'}---${item.tgl ?? 'Unknown Date'}',
      );

      List<OfflinePriceMonitoringGroup> displayGroups = [];
      groupedByOutletAndDate.forEach((key, items) {
        final parts = key.split('---');
        displayGroups.add(OfflinePriceMonitoringGroup(
          outletName: parts[0],
          tgl: parts[1],
          items: items,
        ));
      });

      // Urutkan grup, misalnya berdasarkan tanggal terbaru dulu, lalu nama outlet
      displayGroups.sort((a, b) {
        // Handle null/invalid dates if necessary
        int dateComp = (b.tgl ?? '').compareTo(a.tgl ?? ''); // Descending by date
        if (dateComp != 0) return dateComp;
        return a.outletName.compareTo(b.outletName); // Ascending by outlet name
      });

      return displayGroups;
    } catch (e) {
      _logger.e(_tag, "Error fetching offline Price Monitoring data for display: $e");
      rethrow;
    }
  }

  Future<bool> syncOfflinePriceMonitoringData() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedPriceMonitoringEntries();
      if (rawData.isEmpty) {
        _logger.d(_tag, "No Price Monitoring data to sync.");
        return true;
      }

      final List<PriceMonitoringEntryModel> unsyncedEntries = rawData.map((map) => PriceMonitoringEntryModel.fromMapDb(map)).toList();

      bool apiSuccess = await submitPriceMonitoringOnline(unsyncedEntries);

      if (apiSuccess) {
        List<int> syncedIds = unsyncedEntries.map((item) => item.localId!).whereType<int>().toList();
        if (syncedIds.isNotEmpty) {
          await _dbHelper.deletePriceMonitoringEntriesByIds(syncedIds);
          _logger.d(_tag, "Successfully synced and deleted ${syncedIds.length} price monitoring entries.");
        }
        return true;
      } else {
        _logger.w(_tag, "API call failed for Price Monitoring sync.");
        return false;
      }
    } catch (e) {
      _logger.e(_tag, "Error syncing Price Monitoring data: $e");
      return false;
    }
  }
}

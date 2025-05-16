// lib/services/oos_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';
import 'package:impact_app/screens/product/oos/model/oos_offline_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:collection/collection.dart';

class OOSApiService {

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();
  final String _tag = "OosApiService";

  Future<List<OfflineOOSGroup>> getOfflineOOSForDisplay() async {
    try {
      final List<OOSItem> allOosItems = await _dbHelper.getAllOOSItems();
      if (allOosItems.isEmpty) {
        return [];
      }

      // Kelompokkan berdasarkan outletName dan tgl
      var groupedByOutletAndDate = groupBy<OOSItem, String>(
        allOosItems,
        (item) => '${item.outletName ?? 'Unknown Outlet'}---${item.tgl}',
      );

      List<OfflineOOSGroup> displayGroups = [];
      groupedByOutletAndDate.forEach((key, items) {
        final parts = key.split('---');
        displayGroups.add(OfflineOOSGroup(
          outletName: parts[0],
          tgl: parts[1],
          items: items,
        ));
      });

      // Urutkan grup, misalnya berdasarkan tanggal terbaru dulu, lalu nama outlet
      displayGroups.sort((a, b) {
        int dateComp = b.tgl.compareTo(a.tgl); // Descending by date
        if (dateComp != 0) return dateComp;
        return a.outletName.compareTo(b.outletName); // Ascending by outlet name
      });

      return displayGroups;
    } catch (e) {
      _logger.e(_tag, "Error fetching offline OOS data for display: $e");
      rethrow;
    }
  }

  Future<bool> syncOfflineOOSData() async {
    try {
      final List<OOSItem> unsyncedItems = await _dbHelper.getUnsyncedOOSItems();
      if (unsyncedItems.isEmpty) {
        _logger.d(_tag, "No OOS data to sync.");
        return true; // Tidak ada data, dianggap berhasil
      }

      //List<Map<String, dynamic>> payload = unsyncedItems.map((item) => item.toJsonAPI()).toList();
      
      //_logger.d(_tag, "Syncing OOS data: ${payload.length} items");
      // Ganti ApiConstants.oosSyncEndpoint dengan endpoint API OOS yang sebenarnya
      // Contoh: await _apiClient.post(ApiConstants.oosSyncEndpoint, payload);
      bool apiSuccess = await sendOOSData(unsyncedItems);
      
      // --- SIMULASI PANGGILAN API ---
      //await Future.delayed(const Duration(seconds: 2)); // Hapus ini saat API sebenarnya ada
      //bool apiSuccess = true; // Asumsikan API berhasil untuk simulasi
      // --- AKHIR SIMULASI ---

      // Jika API berhasil, hapus data dari lokal atau tandai sebagai synced
      if (apiSuccess) {
        List<int> syncedIds = unsyncedItems.map((item) => item.localId!).whereType<int>().toList();
        if (syncedIds.isNotEmpty) {
          // Pilih salah satu: hapus atau update status
          await _dbHelper.deleteMultipleOOSItems(syncedIds);
          // atau:
          // for (int id in syncedIds) {
          //   await _dbHelper.updateOOSItemSyncStatus(id, 1);
          // }
          _logger.d(_tag, "Successfully synced and processed ${syncedIds.length} OOS items.");
        }
        return true;
      } else {
        _logger.w(_tag, "API call failed for OOS sync.");
        return false; // API call gagal
      }
    } catch (e) {
      _logger.e(_tag, "Error syncing OOS data: $e");
      return false; // Error selama proses
    }
  }

  Future<bool> sendOOSData(List<OOSItem> oosItems) async {
    final url = Uri.parse('${ApiConstants.baseApiUrl}/api/oos/create_multiple');
    
    List<Map<String, dynamic>> body = oosItems.map((item) => item.toJsonAPI()).toList();

    try {
      print('Sending OOS Data: ${jsonEncode(body)}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Tambahkan header otentikasi jika diperlukan (misal: 'Authorization': 'Bearer YOUR_TOKEN')
        },
        body: jsonEncode(body),
      );

      print('OOS API Response Status: ${response.statusCode}');
      print('OOS API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) { // 201 biasanya untuk created
        // Anda mungkin ingin mem-parse respons jika ada data penting yang dikembalikan
        return true;
      } else {
        // Tangani error spesifik berdasarkan status code jika perlu
        print('Failed to send OOS data: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending OOS data: $e');
      return false;
    }
  }
}
import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/open_ending/models/open_ending_offline_model.dart';
import 'package:impact_app/utils/logger.dart';

class OpenEndingApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'OpenEndingApiService';

  Future<bool> submitOpenEndingData(List<Map<String, dynamic>> openEndingItems) async {
    try {
      _logger.d(_tag, 'Submitting Open Ending data: $openEndingItems');
      // The ApiClient.post method already prepends the baseApiUrl
      final response = await _client.post(ApiConstants.openEnding, openEndingItems);
      _logger.d(_tag, 'Open Ending submission response: $response');
      // Assuming a successful response means the data was accepted.
      // You might need to check specific fields in the response.
      return true; // Or based on response content
    } catch (e) {
      _logger.e(_tag, 'Error submitting Open Ending data: $e');
      return false;
    }
  }

  // METODE BARU: Mengambil dan mengelompokkan data Open Ending offline untuk ditampilkan
  Future<List<OfflineOpenEndingGroup>> getOfflineOpenEndingForDisplay() async {
    _logger.d(_tag, 'Fetching offline Open Ending data for display...');
    final List<Map<String, dynamic>> rawData = await DatabaseHelper.instance.getAllOpenEndingData();
    
    if (rawData.isEmpty) {
      _logger.i(_tag, 'No offline Open Ending data found.');
      return [];
    }

    Map<String, OfflineOpenEndingGroup> groupedData = {};

    for (var row in rawData) {
      // Ambil kunci untuk grouping: outletId dan tgl
      String outletId = row['id_outlet'] as String? ?? 'UNKNOWN_OUTLET';
      String outletName = row['outlet_name'] as String? ?? 'Outlet Tidak Diketahui';
      String tgl = row['tgl'] as String? ?? 'UNKNOWN_DATE';
      String principleId = (row['id_principle'] as int?)?.toString() ?? 'UNKNOWN_PRINCIPLE';
      String userId = row['sender'] as String? ?? 'UNKNOWN_USER';

      String groupKey = '$outletId-$tgl';

      OfflineOpenEndingProduct productDetail = OfflineOpenEndingProduct.fromMap(row);

      if (groupedData.containsKey(groupKey)) {
        groupedData[groupKey]!.products.add(productDetail);
      } else {
        groupedData[groupKey] = OfflineOpenEndingGroup(
          outletId: outletId,
          outletName: outletName,
          tgl: tgl,
          principleId: principleId,
          userId: userId,
          products: [productDetail],
        );
      }
    }
    _logger.d(_tag, 'Found ${groupedData.length} groups of offline Open Ending data.');
    return groupedData.values.toList();
  }

  // METODE BARU: Sinkronisasi semua data Open Ending offline ke server
  Future<bool> syncOfflineOpenEndingData() async {
    _logger.i(_tag, 'Starting offline Open Ending data synchronization...');
    List<OfflineOpenEndingGroup> offlineGroups = await getOfflineOpenEndingForDisplay();

    if (offlineGroups.isEmpty) {
      _logger.i(_tag, 'No offline Open Ending data to sync.');
      return true; // Tidak ada data, dianggap berhasil
    }

    bool allSyncSuccess = true;
    List<int> successfullySyncedDbIds = [];

    for (OfflineOpenEndingGroup group in offlineGroups) {
      _logger.d(_tag, 'Syncing group for outlet: ${group.outletName}, date: ${group.tgl}');
      
      List<Map<String, dynamic>> itemsForApi = [];
      List<int> currentGroupDbIds = [];

      for (OfflineOpenEndingProduct oeProduct in group.products) {
        itemsForApi.add({
          "id_principle": int.tryParse(group.principleId), // Principle ID dari grup
          "id_outlet": int.tryParse(group.outletId),     // Outlet ID dari grup
          "id_product": int.tryParse(oeProduct.productId),
          "SF": oeProduct.sf,
          "SI": oeProduct.si,
          "SA": oeProduct.sa,
          "SO": oeProduct.so,
          "ket": oeProduct.ket ?? '',
          "sender": int.tryParse(group.userId), // User ID (sender) dari grup
          "tgl": group.tgl,                   // Tanggal dari grup
          "selving": oeProduct.selving ?? '',
          "expired": oeProduct.expiredDate ?? '', // Pastikan format YYYY-MM-DD jika API mengharapkan
          "listing": oeProduct.listing ?? '',
          "return": oeProduct.returnQty ?? 0,
          "return_reason": oeProduct.returnReason,
        });
        currentGroupDbIds.add(oeProduct.dbId);
      }

      if (itemsForApi.isEmpty) {
        _logger.w(_tag, "Skipping empty group for outlet ${group.outletName}, date ${group.tgl}");
        continue;
      }
      
      _logger.d(_tag, "Prepared API payload for group ${group.outletName} - ${group.tgl}: $itemsForApi");

      bool successThisGroup = await submitOpenEndingData(itemsForApi);

      if (successThisGroup) {
        _logger.i(_tag, 'Group synced successfully to API: ${group.outletName} - ${group.tgl}');
        successfullySyncedDbIds.addAll(currentGroupDbIds);
      } else {
        _logger.e(_tag, 'Failed to sync group to API: ${group.outletName} - ${group.tgl}.');
        allSyncSuccess = false;
        // Pertimbangkan: apakah harus berhenti jika satu grup gagal?
        // Untuk saat ini, lanjutkan dan coba sinkronkan grup lain.
      }
    }

    if (successfullySyncedDbIds.isNotEmpty) {
      _logger.i(_tag, 'Deleting ${successfullySyncedDbIds.length} synced Open Ending items from local DB.');
      await DatabaseHelper.instance.deleteOpenEndingDataByIds(successfullySyncedDbIds);
    } else {
       _logger.i(_tag, 'No Open Ending items were successfully synced to be deleted.');
    }

    _logger.i(_tag, 'Offline Open Ending data synchronization finished. Overall success: $allSyncSuccess');
    return allSyncSuccess;
  }
}
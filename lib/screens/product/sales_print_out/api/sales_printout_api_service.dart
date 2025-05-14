import 'dart:io';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/sales_print_out/model/sales_print_out_offline_models.dart';
import 'package:intl/intl.dart';
import '../../../../api/api_client.dart';
import '../../../../api/api_constants.dart';
import '../../../../models/product_sales_model.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/session_manager.dart';

class SalesByPrintOutApiService {
  final ApiClient _client = ApiClient();
  final Logger _logger = Logger();
  final String _tag = 'SalesApiService';

  // Submit data Sales Print Out
  Future<bool> submitSalesPrintOut(List<ProductSales> products, List<File?> photos) async {
    try {
      //_logger.d(_tag, 'Submitting sales print out for store: $storeId, visit: $visitId');
      
      // Get user ID from session
      final user = await SessionManager().getCurrentUser();
      final outlet = await SessionManager().getStoreData();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found');
        return false;
      }

      if (outlet == null ) {
        _logger.e(_tag, 'Outlet data not found');
        return false;
      }
      
      // Create sales print out data
      _logger.e("TOTAL PRODUCT", products.length.toString());
      List<Map<String, String>> items = [];
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        items.add({
          'id_product[$i]': product.id ?? '0',
          'qty[$i]': product.sellOutQty.toString(),
          'total[$i]': product.sellOutValue.toString(),
          'periode[$i]': product.periode,
        });
      }
      
      final Map<String, String> requestData = {
        'id_outlet': outlet.idOutlet ?? '',
        'id_principle': user.idpriciple ?? '',
        'id_user': user.idLogin ?? ''
      };
      
      _logger.d(_tag, 'Request data: $requestData');
      
      // Submit data
      final response = await _client.uploadFileMultiples(
        ApiConstants.salesPrintOut,
        photos,
        requestData,
        items
      );
      
      // Log response for debugging
      _logger.d(_tag, 'Submit response: $response');
      
      if (response == null) {
        _logger.e(_tag, 'Invalid response format: $response');
        return false;
      }
      
      // Get sales print out ID
      //final salesPrintOutId = response['id'];
      
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error submitting sales print out: $e');
      return false;
    }
  }
  
  // MODIFIKASI: Save sales print out offline
  Future<bool> saveSalesPrintOutOffline(List<ProductSales> products, List<String?> photoPaths) async { // Ubah File? menjadi String? untuk path
    try {
      _logger.d(_tag, 'Saving sales print out offline');
      
      final user = await SessionManager().getCurrentUser();
      final outlet = await SessionManager().getStoreData();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found for saving offline');
        return false;
      }
      if (outlet == null) {
        _logger.e(_tag, 'Outlet data not found for saving offline');
        return false;
      }

      var now = DateTime.now();
      var formatter = DateFormat('yyyy-MM-dd');
      String formattedDate = formatter.format(now);
      
      List<Map<String, dynamic>> itemsToSave = []; // Ubah tipe Map value ke dynamic
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        itemsToSave.add({
          'id_product': product.id ?? '0',
          'product_name': product.name ?? 'Nama Produk Tidak Diketahui', // SIMPAN NAMA PRODUK
          'qty': product.sellOutQty.toString(),
          'total': product.sellOutValue.toString(),
          'periode': product.periode,
          'image': photoPaths[i] ?? '', // Simpan path gambar
          'id_outlet': outlet.idOutlet ?? '',
          'id_principle': user.idpriciple ?? '',
          'id_user': user.idLogin ?? '',
          'tgl': formattedDate, // Sebaiknya simpan tanggal, bukan user.idLogin
          'outlet': outlet.nama ?? ''
        });
      }
      
      await DatabaseHelper.instance.insertData('sales_print_outs', itemsToSave);
      
      _logger.d(_tag, 'Sales print out saved offline with ${itemsToSave.length} items.');
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error saving sales print out offline: $e');
      return false;
    }
  }

  // METODE BARU: Mengambil dan mengelompokkan data sales print out offline untuk ditampilkan
  Future<List<OfflineSalesGroup>> getOfflineSalesForDisplay() async {
    _logger.d(_tag, 'Fetching offline sales for display...');
    final List<Map<String, dynamic>> rawData = await DatabaseHelper.instance.getAllSalesPrintOuts();
    if (rawData.isEmpty) {
      _logger.i(_tag, 'No offline sales data found.');
      return [];
    }

    // Kelompokkan data berdasarkan kombinasi unik: outletName, outletId, periode, principleId, userId
    // Ini penting karena API call per submit adalah untuk satu "header" ini.
    Map<String, OfflineSalesGroup> groupedData = {};

    for (var row in rawData) {
      String outletName = row['outlet'] as String? ?? 'Outlet Tidak Diketahui';
      String outletId = row['id_outlet'] as String? ?? '';
      String periode = row['periode'] as String? ?? '';
      String principleId = row['id_principle'] as String? ?? '';
      String userId = row['id_user'] as String? ?? '';
      String tgl = row['tgl'] as String? ?? ''; // Jika diperlukan

      // Buat kunci unik untuk pengelompokan
      String groupKey = '$outletId-$tgl-$principleId-$userId';

      OfflineSalesProductDetail productDetail = OfflineSalesProductDetail.fromMap(row);

      if (groupedData.containsKey(groupKey)) {
        groupedData[groupKey]!.products.add(productDetail);
      } else {
        groupedData[groupKey] = OfflineSalesGroup(
          outletName: outletName,
          outletId: outletId,
          principleId: principleId,
          userId: userId,
          tgl: tgl,
          products: [productDetail],
        );
      }
    }
    _logger.d(_tag, 'Found ${groupedData.length} groups of offline sales.');
    return groupedData.values.toList();
  }

  // METODE BARU: Sinkronisasi semua data offline ke server
  Future<bool> syncOfflineSalesData() async {
    _logger.i(_tag, 'Starting offline sales data synchronization...');
    List<OfflineSalesGroup> offlineGroups = await getOfflineSalesForDisplay();

    if (offlineGroups.isEmpty) {
      _logger.i(_tag, 'No offline data to sync.');
      return true; // Tidak ada data, dianggap berhasil (tidak ada yang gagal)
    }

    bool allSyncSuccess = true;
    List<int> successfullySyncedDbIds = [];

    for (OfflineSalesGroup group in offlineGroups) {
      _logger.d(_tag, 'Syncing group for outlet: ${group.outletName}');
      
      List<Map<String, String>> itemsForApi = [];
      List<File?> photosForApi = []; // List File? untuk API
      List<int> currentGroupDbIds = [];

      int n = 0;
      for (OfflineSalesProductDetail productDetail in group.products) {
        itemsForApi.add({
          'id_product[$n]': productDetail.productId,
          'qty[$n]': productDetail.qty,
          'total[$n]': productDetail.total,
          'periode[$n]': productDetail.periode, // Periode dari grup
        });
        
        // Konversi path gambar ke File object
        if (productDetail.imagePath.isNotEmpty && await File(productDetail.imagePath).exists()) {
          photosForApi.add(File(productDetail.imagePath));
        } else {
          photosForApi.add(null); // Tambahkan null jika path kosong atau file tidak ada
           _logger.w(_tag, 'Image not found or path empty for product ${productDetail.productId}: ${productDetail.imagePath}');
        }
        currentGroupDbIds.add(productDetail.dbId);

        n += 1;
      }

      // Data request untuk API, menggunakan ID dari grup yang disinkronkan
      final Map<String, String> requestData = {
        'id_outlet': group.outletId,
        'id_principle': group.principleId,
        'id_user': group.userId,
      };
      _logger.d(_tag, 'Request data for sync: $requestData, items: ${itemsForApi.length}');

      try {
        // Panggil _client.uploadFileMultiples secara langsung
        final response = await _client.uploadFileMultiples(
          ApiConstants.salesPrintOut, // Pastikan endpoint ini benar
          photosForApi,
          requestData,
          itemsForApi
        );

       // _logger.d(_tag, 'API response for group ${group.outletName} - ${group.periode}: $response');

        // Asumsi response memiliki struktur seperti {'status': 'success', ...} atau sejenisnya
        // Sesuaikan pengecekan ini dengan respons aktual API Anda
        if (response != null ) { // Contoh kondisi sukses
          //_logger.i(_tag, 'Group synced successfully: ${group.outletName} - ${group.periode}');
          successfullySyncedDbIds.addAll(currentGroupDbIds);
        } else {
          //_logger.e(_tag, 'Failed to sync group: ${group.outletName} - ${group.periode}. Response: $response');
          allSyncSuccess = false;
          // Pertimbangkan: apakah harus berhenti jika satu grup gagal, atau lanjutkan?
          // Untuk saat ini, lanjutkan dan coba sinkronkan grup lain.
        }
      } catch (e) {
        //_logger.e(_tag, 'Error syncing group ${group.outletName} - ${group.periode}: $e');
        allSyncSuccess = false;
      }
    }

    if (successfullySyncedDbIds.isNotEmpty) {
      _logger.i(_tag, 'Deleting ${successfullySyncedDbIds.length} synced items from local DB.');
      await DatabaseHelper.instance.deleteSalesPrintOutsByIds(successfullySyncedDbIds);
    } else {
       _logger.i(_tag, 'No items were successfully synced to be deleted.');
    }

    _logger.i(_tag, 'Offline sales data synchronization finished. Overall success: $allSyncSuccess');
    return allSyncSuccess;
  }
  
}
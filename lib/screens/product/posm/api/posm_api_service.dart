// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/posm/model/posm_models.dart';
import 'package:impact_app/screens/product/posm/model/posm_offline_model.dart';
import 'package:impact_app/utils/logger.dart';

class PosmApiService {

  final Logger _logger = Logger(); // Tambahkan Logger
  final String _tag = 'PosmApiService'; // Tag untuk logging
  // CATATAN PENTING: URL untuk GET POSM Type dan GET POSM Status yang Anda berikan sama dengan URL POST.
  // Ini kemungkinan keliru. Seharusnya URL GET berbeda.
  // Contoh di bawah menggunakan URL yang Anda berikan, namun Anda mungkin perlu menggantinya
  // dengan URL GET yang benar, misalnya:
  // final String _baseUrl = 'https://api.impactdigitalreport.com/public/api';
  // Future<List<PosmType>> getPosmTypes() async {
  //   final response = await http.get(Uri.parse('$_baseUrl/posm-types')); // Contoh URL yang benar
  // ...

  Future<List<PosmType>> getPosmTypes() async {
    // Menggunakan URL dari permintaan Anda, harap verifikasi ini.
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/posm/type'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => PosmType.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load POSM Types');
    }
  }

  Future<List<PosmStatus>> getPosmStatus() async {
    // Menggunakan URL dari permintaan Anda, harap verifikasi ini.
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/posm/status'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => PosmStatus.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load POSM Status');
    }
  }

  Future<bool> submitPosmData({
    required List<Map<String, String>> posmEntries, // Sesuaikan tipe data jika perlu
    required List<File> imageFiles, // Dari POSMItem.image
  }) async {
    var uri = Uri.parse('${ApiConstants.baseApiUrl}/api/posm/create_multiple');
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan posm_entries
    for (int i = 0; i < posmEntries.length; i++) {
      request.fields['posm_entries[$i][id_user]'] = posmEntries[i]['id_user']!;
      request.fields['posm_entries[$i][id_pinciple]'] = posmEntries[i]['id_pinciple']!;
      request.fields['posm_entries[$i][id_outlet]'] = posmEntries[i]['id_outlet']!;
      request.fields['posm_entries[$i][type]'] = posmEntries[i]['type']!; // Ini seharusnya ID atau nama sesuai spek API
      request.fields['posm_entries[$i][posm_status]'] = posmEntries[i]['posm_status']!; // Ini juga
      request.fields['posm_entries[$i][quantity]'] = posmEntries[i]['quantity']!;
      request.fields['posm_entries[$i][ket]'] = posmEntries[i]['ket']!;
    }

    // Tambahkan image_files
    for (int i = 0; i < imageFiles.length; i++) {
      if (imageFiles[i] != null) {
        var stream = http.ByteStream(imageFiles[i].openRead());
        var length = await imageFiles[i].length();
        var multipartFile = http.MultipartFile(
          'image_files[$i]', // Sesuai nama field di API
          stream,
          length,
          filename: imageFiles[i].path.split('/').last,
        );
        request.files.add(multipartFile);
      }
    }

    try {
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: $respStr');
      return response.statusCode == 200 || response.statusCode == 201; // Sesuaikan dengan kode sukses API Anda
    } catch (e) {
      print('Error submitting POSM data: $e');
      return false;
    }
  }

  // METODE BARU: Mengambil dan mengelompokkan data POSM offline untuk ditampilkan
  Future<List<OfflinePosmGroup>> getOfflinePosmForDisplay() async {
    _logger.d(_tag, 'Fetching offline POSM entries for display...');
    final List<Map<String, dynamic>> rawData = await DatabaseHelper.instance.getAllUnsyncedPosmEntries();
    
    if (rawData.isEmpty) {
      _logger.i(_tag, 'No offline POSM entries found.');
      return [];
    }

    Map<String, OfflinePosmGroup> groupedData = {};

    for (var row in rawData) {
      String outletId = row['id_outlet'] as String? ?? 'UNKNOWN_OUTLET';
      String outletName = row['outlet_name'] as String? ?? 'Outlet Tidak Diketahui';
      String timestamp = row['timestamp'] as String? ?? DateTime(0).toIso8601String(); // Default jika null
      String userId = row['id_user'] as String? ?? 'UNKNOWN_USER';
      String principleId = row['id_pinciple'] as String? ?? 'UNKNOWN_PRINCIPLE';
      String? visitId = row['visit_id'] as String?;

      // Kunci grup berdasarkan outlet dan timestamp (satu sesi input)
      String groupKey = '$outletId-$timestamp';

      OfflinePosmItemDetail itemDetail = OfflinePosmItemDetail.fromMap(row);

      if (groupedData.containsKey(groupKey)) {
        groupedData[groupKey]!.items.add(itemDetail);
      } else {
        groupedData[groupKey] = OfflinePosmGroup(
          outletId: outletId,
          outletName: outletName,
          timestamp: timestamp,
          userId: userId,
          principleId: principleId,
          visitId: visitId,
          items: [itemDetail],
        );
      }
    }
    _logger.d(_tag, 'Found ${groupedData.length} groups of offline POSM entries.');
    return groupedData.values.toList();
  }

  // METODE BARU: Sinkronisasi semua data POSM offline ke server
  Future<bool> syncOfflinePosmData() async {
    _logger.i(_tag, 'Starting offline POSM data synchronization...');
    List<OfflinePosmGroup> offlineGroups = await getOfflinePosmForDisplay();

    if (offlineGroups.isEmpty) {
      _logger.i(_tag, 'No offline POSM data to sync.');
      return true; // Tidak ada data, dianggap berhasil
    }

    bool allSyncSuccess = true;
    List<int> successfullySyncedDbIds = [];

    for (OfflinePosmGroup group in offlineGroups) {
      _logger.d(_tag, 'Syncing POSM group for outlet: ${group.outletName}, timestamp: ${group.timestamp}');
      
      List<Map<String, String>> entriesForApi = [];
      List<File> imageFilesForApi = [];
      List<int> currentGroupDbIds = [];

      for (OfflinePosmItemDetail itemDetail in group.items) {
        entriesForApi.add({
          'id_user': group.userId,
          'id_pinciple': group.principleId,
          'id_outlet': group.outletId,
          'type': itemDetail.type ?? '', // Pastikan ini ID jika API mengharapkan ID
          'posm_status': itemDetail.posmStatus ?? '', // Pastikan ini ID jika API mengharapkan ID
          'quantity': (itemDetail.quantity ?? 0).toString(),
          'ket': itemDetail.ket ?? '',
        });
        if (itemDetail.imagePath != null && itemDetail.imagePath!.isNotEmpty) {
          File imageFile = File(itemDetail.imagePath!);
          if (await imageFile.exists()) {
            imageFilesForApi.add(imageFile);
          } else {
             _logger.w(_tag, "Image file not found at path: ${itemDetail.imagePath} for dbId: ${itemDetail.dbId}");
          }
        }
        currentGroupDbIds.add(itemDetail.dbId);
      }

      if (entriesForApi.isEmpty) {
        _logger.w(_tag, "Skipping empty POSM group for outlet ${group.outletName}, timestamp ${group.timestamp}");
        continue;
      }
      // Pastikan jumlah imageFilesForApi sesuai dengan ekspektasi API jika API memerlukan 1 gambar per entri
      // Jika API /create_multiple mengharapkan image_files[index] sesuai dengan posm_entries[index]
      // dan beberapa entri mungkin tidak punya gambar, maka perlu penyesuaian.
      // Untuk saat ini, kita kirim semua gambar yang ada.

      bool successThisGroup = await submitPosmData(
        posmEntries: entriesForApi,
        imageFiles: imageFilesForApi,
      );

      if (successThisGroup) {
        _logger.i(_tag, 'POSM Group synced successfully to API: ${group.outletName} - ${group.timestamp}');
        successfullySyncedDbIds.addAll(currentGroupDbIds);
      } else {
        _logger.e(_tag, 'Failed to sync POSM group to API: ${group.outletName} - ${group.timestamp}.');
        allSyncSuccess = false;
      }
    }

    if (successfullySyncedDbIds.isNotEmpty) {
      _logger.i(_tag, 'Deleting ${successfullySyncedDbIds.length} synced POSM items from local DB.');
      await DatabaseHelper.instance.deletePosmEntriesByIds(successfullySyncedDbIds);
    } else {
       _logger.i(_tag, 'No POSM items were successfully synced to be deleted.');
    }

    _logger.i(_tag, 'Offline POSM data synchronization finished. Overall success: $allSyncSuccess');
    return allSyncSuccess;
  }
}
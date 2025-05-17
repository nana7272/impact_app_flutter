// File BARU: /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/api/activation_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http; // Import http
import 'package:impact_app/api/api_client.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/activation/model/activation_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart'; // Untuk token

class ActivationApiService {
  final ApiClient _apiClient = ApiClient(); // Gunakan instance ApiClient yang sudah ada
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();
  final String _tag = "ActivationApiService";

  Future<List<String>> fetchPrograms(String idPrinciple) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/activation/program/$idPrinciple'));
    _logger.i("API Fetch Programs", "URL: ${'${ApiConstants.baseApiUrl}/api/activation/program/$idPrinciple'}, Response Code: ${response.statusCode}, Body: ${response.body}");
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item['nama'] as String).toList();
    } else {
      throw Exception('Failed to load programs. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<String>> fetchPeriods(String idPrinciple) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/activation/periode/$idPrinciple'));
    _logger.i("API Fetch Periods", "URL: ${'${ApiConstants.baseApiUrl}/api/activation/periode/$idPrinciple'}, Response Code: ${response.statusCode}, Body: ${response.body}");
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item['nama'] as String).toList();
    } else {
      throw Exception('Failed to load periods. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> submitActivationOnline(List<ActivationEntryModel> entries) async {
    if (entries.isEmpty) return true;

    final String? token = await SessionManager().getToken();
    if (token == null) {
      _logger.e(_tag, "Token not found for API call.");
      return false;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseApiUrl}/api/activation/create_multiple'), // Pastikan endpoint benar
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      request.fields['activation_entries[$i][id_user]'] = entry.idUser;
      request.fields['activation_entries[$i][id_pinciple]'] = entry.idPinciple;
      request.fields['activation_entries[$i][id_outlet]'] = entry.idOutlet;
      request.fields['activation_entries[$i][tgl]'] = entry.tgl;
      request.fields['activation_entries[$i][program]'] = entry.program;
      request.fields['activation_entries[$i][range]'] = entry.rangePeriode; // Sesuai API 'range'
      request.fields['activation_entries[$i][outlet_customer]'] = entry.outletName ?? entry.idOutlet; // Sesuai API 'outlet_customer'
      if (entry.keterangan != null) {
        request.fields['activation_entries[$i][keterangan]'] = entry.keterangan!;
      }

      if (entry.imageFile != null && entry.imageFile!.existsSync()) {

        if (entry.imageFile?.path == null || entry.imageFile?.path?.isEmpty == true) {
          request.files.add(http.MultipartFile.fromBytes('image_files[$i]', [], filename: ''));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
          'image_files[$i]', // Sesuai API 'image_files[index]'
          entry.imageFile!.path,
        ));
        }

        
      } else if (entry.imagePath != null && File(entry.imagePath!).existsSync()) {
         // Jika mengirim dari data offline yang hanya punya imagePath
         if (entry.imagePath?.isEmpty == true) {
            request.files.add(http.MultipartFile.fromBytes('image_files[$i]', [], filename: ''));
         } else {
            request.files.add(await http.MultipartFile.fromPath(
              'image_files[$i]',
              entry.imagePath!,
            ));
         }
      }  
    }
    _logger.d(_tag, "Sending ${entries.length} activation entries to API. Fields: ${request.fields.length}, Files: ${request.files.length}");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logger.d(_tag, "API Response Status: ${response.statusCode}");
      _logger.d(_tag, "API Response Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        _logger.e(_tag, "API Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      _logger.e(_tag, "Error submitting activation online: $e");
      return false;
    }
  }

  Future<bool> saveActivationOffline(List<ActivationEntryModel> entries) async {
    if (entries.isEmpty) return true;
    int successCount = 0;
    try {
      for (var entry in entries) {
        await _dbHelper.insertActivationEntry(entry.toMapForDb());
        successCount++;
      }
      _logger.d(_tag, "Saved $successCount activation entries to local DB.");
      return successCount == entries.length;
    } catch (e) {
      _logger.e(_tag, "Error saving activation offline: $e");
      return false;
    }
  }
  
  Future<List<OfflineActivationGroup>> getOfflineActivationsForDisplay() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedActivationEntries();
      if (rawData.isEmpty) return [];

      final List<ActivationEntryModel> allEntries = rawData.map((map) => ActivationEntryModel.fromMapDb(map)).toList();

      var groupedByOutletAndDate = groupBy<ActivationEntryModel, String>(
        allEntries,
        (item) => '${item.outletName ?? 'Unknown Outlet'}---${item.tgl}',
      );

      List<OfflineActivationGroup> displayGroups = [];
      groupedByOutletAndDate.forEach((key, items) {
        final parts = key.split('---');
        displayGroups.add(OfflineActivationGroup(
          outletName: parts[0],
          tgl: parts[1],
          items: items,
        ));
      });

      displayGroups.sort((a, b) {
        int dateComp = b.tgl.compareTo(a.tgl);
        if (dateComp != 0) return dateComp;
        return a.outletName.compareTo(b.outletName);
      });
      return displayGroups;
    } catch (e) {
      _logger.e(_tag, "Error fetching offline activations for display: $e");
      rethrow;
    }
  }

  Future<bool> syncOfflineActivationData() async {
    try {
      final List<Map<String, dynamic>> rawData = await _dbHelper.getUnsyncedActivationEntries();
      if (rawData.isEmpty) {
        _logger.d(_tag, "No activation data to sync.");
        return true;
      }
      
      final List<ActivationEntryModel> unsyncedEntries = rawData.map((map) => ActivationEntryModel.fromMapDb(map)).toList();
      
      bool apiSuccess = await submitActivationOnline(unsyncedEntries);

      if (apiSuccess) {
        List<int> syncedIds = unsyncedEntries.map((item) => item.localId!).whereType<int>().toList();
        if (syncedIds.isNotEmpty) {
          await _dbHelper.deleteActivationEntriesByIds(syncedIds);
          _logger.d(_tag, "Successfully synced and deleted ${syncedIds.length} activation entries.");
        }
        return true;
      } else {
        _logger.w(_tag, "API call failed for activation sync.");
        return false;
      }
    } catch (e) {
      _logger.e(_tag, "Error syncing activation data: $e");
      return false;
    }
  }
}

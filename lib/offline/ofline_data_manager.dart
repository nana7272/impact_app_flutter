import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class OfflineDataManager {
  static final OfflineDataManager _instance = OfflineDataManager._internal();
  final Logger _logger = Logger();
  final String _tag = 'OfflineDataManager';
  
  // Keys for different data types
  static const String _availabilityDataKey = 'offline_availability_data';
  
  factory OfflineDataManager() {
    return _instance;
  }
  
  OfflineDataManager._internal();
  
  // Save availability data offline
  Future<bool> saveAvailabilityData({
    required String storeId,
    required String visitId,
    required List<Map<String, dynamic>> productsData,
    required Map<String, String?> imagePaths,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Create data structure for storage
      Map<String, dynamic> dataItem = {
        'store_id': storeId,
        'visit_id': visitId,
        'products': productsData,
        'image_paths': imagePaths,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      
      // Get existing data
      List<String> dataList = prefs.getStringList(_availabilityDataKey) ?? [];
      
      // Check if entry for this store/visit already exists
      int existingIndex = -1;
      for (int i = 0; i < dataList.length; i++) {
        Map<String, dynamic> item = json.decode(dataList[i]);
        if (item['store_id'] == storeId && item['visit_id'] == visitId) {
          existingIndex = i;
          break;
        }
      }
      
      // Update or add
      if (existingIndex >= 0) {
        dataList[existingIndex] = json.encode(dataItem);
      } else {
        dataList.add(json.encode(dataItem));
      }
      
      // Save back to storage
      await prefs.setStringList(_availabilityDataKey, dataList);
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error saving availability data offline: $e');
      return false;
    }
  }
  
  // Get all unsynchronized availability data
  Future<List<Map<String, dynamic>>> getUnsyncedAvailabilityData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> dataList = prefs.getStringList(_availabilityDataKey) ?? [];
      List<Map<String, dynamic>> result = [];
      
      for (String item in dataList) {
        Map<String, dynamic> data = json.decode(item);
        if (data['synced'] == false) {
          result.add(data);
        }
      }
      
      return result;
    } catch (e) {
      _logger.e(_tag, 'Error getting unsynced availability data: $e');
      return [];
    }
  }
  
  // Mark availability data as synchronized
  Future<bool> markAvailabilityDataSynced({
    required String storeId, 
    required String visitId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> dataList = prefs.getStringList(_availabilityDataKey) ?? [];
      
      for (int i = 0; i < dataList.length; i++) {
        Map<String, dynamic> data = json.decode(dataList[i]);
        
        if (data['store_id'] == storeId && data['visit_id'] == visitId) {
          data['synced'] = true;
          dataList[i] = json.encode(data);
          break;
        }
      }
      
      await prefs.setStringList(_availabilityDataKey, dataList);
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error marking availability data as synced: $e');
      return false;
    }
  }
  
  // Delete synchronized data to save space
  Future<bool> cleanupSyncedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> dataList = prefs.getStringList(_availabilityDataKey) ?? [];
      List<String> newDataList = [];
      
      for (String item in dataList) {
        Map<String, dynamic> data = json.decode(item);
        if (data['synced'] == false) {
          newDataList.add(item);
        }
      }
      
      await prefs.setStringList(_availabilityDataKey, newDataList);
      return true;
    } catch (e) {
      _logger.e(_tag, 'Error cleaning up synced data: $e');
      return false;
    }
  }
  
  // Get offline data count (for badges)
  Future<int> getUnsyncedDataCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> dataList = prefs.getStringList(_availabilityDataKey) ?? [];
      int count = 0;
      
      for (String item in dataList) {
        Map<String, dynamic> data = json.decode(item);
        if (data['synced'] == false) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      _logger.e(_tag, 'Error counting unsynced data: $e');
      return 0;
    }
  }
}
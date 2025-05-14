import 'dart:convert';
import 'package:impact_app/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class OfflineDataManager {
  final DBHelper _dbHelper = DBHelper();
  final Logger _logger = Logger();
  
  // Generic method to save data offline
  Future<bool> saveDataOffline(String table, Map<String, dynamic> data) async {
    try {
      _logger.d('OfflineDataManager', 'Saving data to $table: $data');
      await _dbHelper.insertData(table, data); // Ensure insertData method exists in DBHelper
      return true;
    } catch (e) {
      _logger.e('OfflineDataManager', 'Error saving data to $table: $e');
      return false;
    }
  }

    // Generic method to get all offline data
  Future<List<Map<String, dynamic>>> getOfflineData(String table) async {
    try {
      _logger.d('OfflineDataManager', 'Getting offline data from $table');
      final List<Map<String, dynamic>> offlineData = await _dbHelper.getAllData(table);  // Ensure getAll method exists in DBHelper
      return offlineData;
    } catch (e) {
      _logger.e('OfflineDataManager', 'Error getting offline data from $table: $e');
      return [];
    }
  }

  // Generic method to mark data as synced
  Future<bool> markDataAsSynced(String table, String idField, dynamic idValue) async {
    try {
      _logger.d('OfflineDataManager', 'Marking data in $table with $idField: $idValue as synced');
      await _dbHelper.updateData(table, { 'is_synced': 1 }, '$idField = ?', [idValue]); // Ensure update method exists in DBHelper
      return true;
    } catch (e) {
      _logger.e('OfflineDataManager', 'Error marking data as synced in $table: $e');
      return false;
    }
  }

  // Generic method to sync data
  Future<bool> syncData(String table, Function submitFunction, {String idField = 'id'}) async {
      try {
        _logger.d('OfflineDataManager', 'Syncing offline data for $table');

        // Get offline data
        final offlineData = await getOfflineData(table);
        if (offlineData.isEmpty) {
          _logger.d('OfflineDataManager', 'No $table data to sync');
          return true;
        }

        for (var data in offlineData) {
          try {
            // Submit data to server
            final success = await submitFunction(data);

            if (success) {
              // Mark data as synced
              await markDataAsSynced(table, idField, data[idField]);
              _logger.d('OfflineDataManager', 'Successfully synced $table data with $idField: ${data[idField]}');
            } else {
              _logger.e('OfflineDataManager', 'Failed to sync $table data with $idField: ${data[idField]}');
            }
          } catch (e) {
            _logger.e('OfflineDataManager', 'Error syncing $table data: $e');
            // Continue with the next data
          }
        }
        return true;
      } catch (e) {
        _logger.e('OfflineDataManager', 'Error syncing offline data for $table: $e');
        return false;
      }
  }
}
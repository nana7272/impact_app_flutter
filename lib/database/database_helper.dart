import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_sales_model.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Logger _logger = Logger();
  final String _tag = 'DatabaseHelper';

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'impact_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    _logger.d(_tag, 'Creating database tables');
    
    // Table for offline sales print out
    await db.execute('''
      CREATE TABLE sales_print_outs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    
    // Table for offline items
    await db.execute('''
      CREATE TABLE sales_print_out_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_print_out_id INTEGER NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        sell_out_qty INTEGER NOT NULL,
        sell_out_value REAL NOT NULL,
        periode TEXT NOT NULL,
        photo_path TEXT,
        FOREIGN KEY (sales_print_out_id) REFERENCES sales_print_outs (id) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a new sales print out
  Future<int> insertSalesPrintOut(Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      // Extract basic info
      final storeId = data['store_id'];
      final visitId = data['visit_id'];
      final userId = data['user_id'];
      final createdAt = data['created_at'];
      
      // Extract items
      final items = data['items'];
      
      // Insert into sales_print_outs table
      final salesPrintOutId = await db.insert(
        'sales_print_outs',
        {
          'store_id': storeId,
          'visit_id': visitId,
          'user_id': userId,
          'created_at': createdAt,
          'status': 'pending',
          'data': json.encode(data),
        },
      );
      
      // Insert items into sales_print_out_items table
      for (var item in items) {
        await db.insert(
          'sales_print_out_items',
          {
            'sales_print_out_id': salesPrintOutId,
            'product_id': item['product_id'],
            'product_name': item['product_name'],
            'sell_out_qty': item['sell_out_qty'],
            'sell_out_value': item['sell_out_value'],
            'periode': item['periode'],
            'photo_path': item['photo_path'],
          },
        );
      }
      
      _logger.d(_tag, 'Sales print out inserted with ID: $salesPrintOutId');
      return salesPrintOutId;
    } catch (e) {
      _logger.e(_tag, 'Error inserting sales print out: $e');
      return -1;
    }
  }

  // Get all pending sales print outs
  Future<List<Map<String, dynamic>>> getPendingSalesPrintOuts() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'sales_print_outs',
        where: 'status = ?',
        whereArgs: ['pending'],
      );
      
      List<Map<String, dynamic>> result = [];
      
      for (var map in maps) {
        // Get items for this sales print out
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'sales_print_out_items',
          where: 'sales_print_out_id = ?',
          whereArgs: [map['id']],
        );
        
        // Add to result
        final data = json.decode(map['data'] as String);
        data['local_id'] = map['id'];
        data['items'] = itemMaps;
        
        result.add(data);
      }
      
      _logger.d(_tag, 'Found ${result.length} pending sales print outs');
      return result;
    } catch (e) {
      _logger.e(_tag, 'Error getting pending sales print outs: $e');
      return [];
    }
  }

  // Update status of a sales print out
  Future<int> updateSalesPrintOutStatus(int id, String status) async {
    try {
      final db = await database;
      
      return await db.update(
        'sales_print_outs',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.e(_tag, 'Error updating sales print out status: $e');
      return 0;
    }
  }

  // Delete a sales print out
  Future<int> deleteSalesPrintOut(int id) async {
    try {
      final db = await database;
      
      // Delete items first (should cascade, but just to be safe)
      await db.delete(
        'sales_print_out_items',
        where: 'sales_print_out_id = ?',
        whereArgs: [id],
      );
      
      // Then delete the sales print out
      return await db.delete(
        'sales_print_outs',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.e(_tag, 'Error deleting sales print out: $e');
      return 0;
    }
  }

  // Get all pending count
  Future<int> getPendingCount() async {
    try {
      final db = await database;
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales_print_outs WHERE status = ?',
        ['pending'],
      );
      
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      _logger.e(_tag, 'Error getting pending count: $e');
      return 0;
    }
  }

  // Metode untuk menghitung jumlah sampling konsumen yang belum disinkronkan
  Future<int> countPendingSamplingKonsumen() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sampling_konsumen WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
// lib/utils/db_helper.dart (Tambahkan ke file yang sudah ada atau buat baru)
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _database;
  static final DBHelper _instance = DBHelper._internal();
  
  factory DBHelper() {
    return _instance;
  }
  
  DBHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'impact_database.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  // Method untuk mendapatkan directory aplikasi
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  Future<void> _createDb(Database db, int version) async {
    // Tabel sampling_konsumen
    await db.execute('''
      CREATE TABLE sampling_konsumen(
        id TEXT PRIMARY KEY,
        store_id TEXT,
        visit_id TEXT,
        nama TEXT,
        no_hp TEXT,
        umur TEXT,
        alamat TEXT,
        email TEXT,
        produk_sebelumnya TEXT,
        produk_yang_dibeli TEXT,
        kuantitas INTEGER,
        keterangan TEXT,
        created_at TEXT,
        is_synced INTEGER
      )
    ''');

    // Tabel promo_audit
    await db.execute('''
      CREATE TABLE promo_audit(
        id TEXT PRIMARY KEY,
        store_id TEXT,
        visit_id TEXT,
        status_promotion INTEGER,
        extra_display INTEGER,
        pop_promo INTEGER,
        harga_promo INTEGER,
        keterangan TEXT,
        photo_url TEXT,
        created_at TEXT,
        is_synced INTEGER
      )
    ''');

    // Tabel sales_print_outs
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

    // Tabel sales_print_out_items
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

    // Tabel open_ending
    await db.execute('''
      CREATE TABLE open_ending (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL
      )
    ''');

    // Tabel posm
    await db.execute('''
      CREATE TABLE posm (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL,
        image_paths TEXT
      )
    ''');

    // Tabel out_of_stock
    await db.execute('''
      CREATE TABLE out_of_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL
      )
    ''');

    // Tabel activation
    await db.execute('''
      CREATE TABLE activation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL,
        image_paths TEXT
      )
    ''');

    // Tabel planogram
    await db.execute('''
      CREATE TABLE planogram (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL,
        before_image_paths TEXT,
        after_image_paths TEXT
      )
    ''');

    // Tabel price_monitoring
    await db.execute('''
      CREATE TABLE price_monitoring (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL
      )
    ''');

    // Tabel competitor
    await db.execute('''
      CREATE TABLE competitor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        items TEXT NOT NULL,
        own_image_paths TEXT,
        competitor_image_paths TEXT
      )
    ''');

    // Tabel availability
    await db.execute('''
      CREATE TABLE availability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL,
        products TEXT NOT NULL
      )
    ''');
    
    // Tabel lain yang mungkin dibutuhkan
  }
  
  // Metode untuk menyimpan data sampling konsumen offline
  Future<int> insertSamplingKonsumen(Map<String, dynamic> data) async {
    final db = await database;
    
    // Generate ID lokal jika belum ada
    if (data['id'] == null) {
      data['id'] = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Set is_synced = 0 (belum tersinkronisasi)
    data['is_synced'] = 0;
    
    // Tambahkan timestamp
    data['created_at'] = DateTime.now().toIso8601String();
    
    return await db.insert(
      'sampling_konsumen',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Mendapatkan daftar data sampling konsumen yang belum disinkronkan
  Future<List<Map<String, dynamic>>> getPendingSamplingKonsumen() async {
    final db = await database;
    
    return await db.query(
      'sampling_konsumen',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }
  
  // Menandai data sampling konsumen sebagai tersinkronisasi
  Future<int> markSamplingKonsumenAsSynced(String id) async {
    final db = await database;
    
    return await db.update(
      'sampling_konsumen',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Mendapatkan semua data sampling konsumen
  Future<List<Map<String, dynamic>>> getAllSamplingKonsumen() async {
    final db = await database;
    
    return await db.query('sampling_konsumen');
  }

  // Method untuk menyimpan data promo audit
Future<int> insertPromoAudit(Map<String, dynamic> data) async {
  final db = await database;
  
  // Set is_synced = 0 (belum tersinkronisasi)
  data['is_synced'] = 0;
  
  return await db.insert(
    'promo_audit',
    data,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Method untuk mendapatkan promo audit berdasarkan store
Future<Map<String, dynamic>?> getPromoAuditByStore(String storeId, String visitId) async {
  final db = await database;
  
  List<Map<String, dynamic>> results = await db.query(
    'promo_audit',
    where: 'store_id = ? AND visit_id = ?',
    whereArgs: [storeId, visitId],
    limit: 1,
  );
  
  if (results.isNotEmpty) {
    return results.first;
  }
  
  return null;
}

// Method untuk mendapatkan daftar promo audit yang belum disinkronkan
Future<List<Map<String, dynamic>>> getPendingPromoAudits() async {
  final db = await database;
  
  return await db.query(
    'promo_audit',
    where: 'is_synced = ?',
    whereArgs: [0],
  );
}

// Method untuk menandai promo audit sebagai tersinkronisasi
Future<int> markPromoAuditAsSynced(String id) async {
  final db = await database;
  
  return await db.update(
    'promo_audit',
    {'is_synced': 1},
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Method untuk menghitung jumlah promo audit yang belum disinkronkan
Future<int> countPendingPromoAudits() async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM promo_audit WHERE is_synced = 0',
  );
  return Sqflite.firstIntValue(result) ?? 0;
}

// Generic method to insert data into a table
  Future<int> insertData(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Generic method to get all data from a table
  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    final db = await database;
    return await db.query(table);
  }

    // Generic method to update data in a table
  Future<int> updateData(String table, Map<String, dynamic> values, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }
}


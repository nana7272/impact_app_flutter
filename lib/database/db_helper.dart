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
}


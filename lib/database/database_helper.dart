import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';
import 'package:impact_app/screens/setting/model/area_model.dart';
import 'package:impact_app/screens/setting/model/kecamatan_model.dart';
import 'package:impact_app/screens/setting/model/kelurahan_model.dart';
import 'package:impact_app/screens/setting/model/outlet_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app_database.db');
    return await openDatabase(
      path,
      version: 17, // Naikkan versi karena ada tabel baru price_monitoring_entries
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // << TAMBAHKAN INI
    );
  }

  // Tambahkan method _onUpgrade
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 17) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS price_monitoring_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_principle TEXT,
          id_outlet TEXT,
          outlet_name TEXT,
          id_product TEXT,
          product_name TEXT,
          harga_normal TEXT,
          harga_diskon TEXT,
          harga_gabungan TEXT,
          ket TEXT,
          sender TEXT,
          tgl TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
      print("Table price_monitoring_entries created or verified on upgrade.");
    }
    if (oldVersion < 16) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activation_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_user TEXT,
          id_pinciple TEXT,
          id_outlet TEXT,
          outlet_name TEXT, 
          tgl TEXT,
          program TEXT,
          range_periode TEXT,
          keterangan TEXT,
          image_path TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
      print("Table activation_entries created or verified on upgrade.");
    }
    if (oldVersion < 15) {
      try {
        await db.execute("ALTER TABLE oos_entries ADD COLUMN outlet_name TEXT");
         print("Column outlet_name added to oos_entries on upgrade.");
      } catch (e) {
        print("Error adding column outlet_name to oos_entries (may already exist): $e");
      }
    }

  }

  Future _onCreate(Database db, int version) async {
    
    //oos
    await db.execute('''
      CREATE TABLE oos_entries (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_principle INTEGER NOT NULL,
        id_outlet INTEGER NOT NULL,
        outlet_name TEXT,
        id_product INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        ket TEXT,
        type TEXT NOT NULL,
        sender INTEGER NOT NULL,
        tgl TEXT NOT NULL,
        is_empty INTEGER NOT NULL DEFAULT 1,
        is_synced INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT 
      )
    ''');

    //posm_entries
    await db.execute('''
      CREATE TABLE posm_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user TEXT,
        id_pinciple TEXT,
        id_outlet TEXT,
        outlet_name TEXT,
        visit_id TEXT, 
        type TEXT,
        posm_status TEXT,
        quantity INTEGER,
        ket TEXT,
        image_path TEXT,
        timestamp TEXT,
        is_synced INTEGER DEFAULT 0 
      )
    ''');

    // Tabel sales_print_outs
    await db.execute('''
      CREATE TABLE sales_print_outs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_product TEXT NOT NULL,
        product_name TEXT NOT NULL, 
        qty TEXT NOT NULL,
        total TEXT NOT NULL,
        periode TEXT NOT NULL,
        image TEXT NOT NULL,
        id_outlet TEXT NOT NULL,
        id_principle TEXT NOT NULL,
        id_user TEXT NOT NULL,
        tgl TEXT NOT NULL,
        outlet TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE areas (
        idArea TEXT PRIMARY KEY,
        kodeArea TEXT,
        nama TEXT,
        lat TEXT,
        lolat TEXT,
        ket TEXT,
        idPropinsi TEXT,
        doc TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE outlets (
        idOutlet TEXT PRIMARY KEY,
        kode TEXT,
        nama TEXT,
        alamat TEXT,
        area TEXT, 
        provinsi TEXT,
        idAccount TEXT,
        ket TEXT,
        doc TEXT,
        status TEXT,
        lat TEXT,
        lolat TEXT,
        id_dc TEXT,
        idusers TEXT,
        pulau TEXT,
        region TEXT,
        id_p TEXT,
        hk TEXT,
        type_store TEXT,
        image TEXT,
        kecamatan TEXT,
        kelurahan TEXT,
        zip_code TEXT,
        segmentasi TEXT,
        subsegmentasi TEXT,
        FOREIGN KEY (area) REFERENCES areas(idArea) 
      )
    ''');
    // Tambahkan FOREIGN KEY jika 'area' di tabel outlets adalah idArea

    await db.execute('''
      CREATE TABLE products (
        idProduk TEXT PRIMARY KEY,
        idBrand TEXT,
        id_kateogri TEXT,
        kode TEXT,
        nama TEXT,
        ket TEXT,
        doc TEXT,
        status TEXT,
        harga TEXT,
        category TEXT,
        gambar TEXT,
        merk TEXT,
        id_size TEXT,
        id_flavour TEXT,
        sku TEXT
        -- idPrinciple TEXT -- Tambahkan jika menyimpan relasi ke principle
      )
    ''');

    await db.execute('''
      CREATE TABLE kecamatans (
        id TEXT PRIMARY KEY,
        nama TEXT,
        id_area TEXT,
        doc TEXT,
        status TEXT,
        FOREIGN KEY (id_area) REFERENCES areas(idArea)
      )
    ''');

    await db.execute('''
      CREATE TABLE kelurahans (
        id TEXT PRIMARY KEY,
        nama TEXT,
        id_kecamatan TEXT,
        id_area TEXT,
        kodepos TEXT,
        doc TEXT,
        status TEXT,
        nama_kecamatan TEXT,
        FOREIGN KEY (id_kecamatan) REFERENCES kecamatans(id)
      )
    ''');

    // Tabel open_ending_data (juga buat di onCreate jika ini instalasi baru)
    await db.execute('''
      CREATE TABLE open_ending_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_principle INTEGER,
        id_outlet TEXT,
        outlet_name TEXT,
        id_product TEXT,
        product_name TEXT, 
        sf INTEGER,
        si INTEGER,
        sa INTEGER,
        so INTEGER,
        ket TEXT,
        sender TEXT,
        tgl TEXT,
        selving TEXT,
        expired_date TEXT,
        listing TEXT,
        return_qty INTEGER,
        return_reason TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabel activation_entries (juga buat di onCreate jika ini instalasi baru)
    await db.execute('''
      CREATE TABLE activation_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user TEXT,
        id_pinciple TEXT,
        id_outlet TEXT,
        outlet_name TEXT, 
        tgl TEXT,
        program TEXT,
        range_periode TEXT,
        keterangan TEXT,
        image_path TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabel price_monitoring_entries (juga buat di onCreate jika ini instalasi baru)
    await db.execute('''
      CREATE TABLE price_monitoring_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_principle TEXT,
        id_outlet TEXT,
        outlet_name TEXT,
        id_product TEXT,
        product_name TEXT,
        harga_normal TEXT,
        harga_diskon TEXT,
        harga_gabungan TEXT,
        ket TEXT,
        sender TEXT,
        tgl TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> insertData(String table, List<Map<String, dynamic>> data) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var area in data) {
      batch.insert(table, area, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- Operasi Insert (dengan conflict replace untuk update jika ada) ---
  Future<int> insertArea(AreaModel area) async {
    Database db = await instance.database;
    return await db.insert('areas', area.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> bulkInsertAreas(List<AreaModel> areas) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var area in areas) {
      batch.insert('areas', area.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }


  Future<int> insertOutlet(OutletModel outlet) async {
    Database db = await instance.database;
    return await db.insert('outlets', outlet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> bulkInsertOutlets(List<OutletModel> outlets) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var outlet in outlets) {
      batch.insert('outlets', outlet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertProduct(ProductModel product) async {
    Database db = await instance.database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
   Future<void> bulkInsertProducts(List<ProductModel> products) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }


  Future<int> insertKecamatan(KecamatanModel kecamatan) async {
    Database db = await instance.database;
    return await db.insert('kecamatans', kecamatan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> bulkInsertKecamatans(List<KecamatanModel> kecamatans) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var kecamatan in kecamatans) {
      batch.insert('kecamatans', kecamatan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertKelurahan(KelurahanModel kelurahan) async {
    Database db = await instance.database;
    return await db.insert('kelurahans', kelurahan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> bulkInsertKelurahans(List<KelurahanModel> kelurahans) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var kelurahan in kelurahans) {
      batch.insert('kelurahans', kelurahan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }


  // --- Operasi Get Count ---
  Future<int> getCount(String tableName, {String? idArea, String? idPrinciple}) async {
    Database db = await instance.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (idArea != null) {
      // Untuk tabel outlets, kecamatans, kelurahans (dan tabel lain yang mungkin memiliki id_area)
      if (tableName == 'outlets' || tableName == 'kecamatans' || tableName == 'kelurahans') {
        whereClause = 'area = ?'; // 'area' adalah nama kolom di tabel outlets
        if(tableName == 'kecamatans' || tableName == 'kelurahans') {
            whereClause = 'id_area = ?'; // 'id_area' di tabel kecamatans
        }
      }
      // Tambahkan kondisi lain jika idArea relevan untuk tabel lain dengan nama kolom yang berbeda
      whereArgs = [idArea];
    } else if (idPrinciple != null) {
      // Khusus untuk tabel products atau tabel lain yang berelasi dengan id_principle
      if (tableName == 'products') {
        // Asumsi Anda akan menambahkan kolom 'idPrinciple' di tabel 'products'
        // Jika tidak, maka count product tidak bisa difilter per principle dari DB lokal
        // kecuali Anda menyimpan semua produk tanpa filter principle dan menghitung semuanya.
        // Sesuai API, offset_product berdasarkan id_principle.
        // whereClause = 'idPrinciple = ?';
        // whereArgs = [idPrinciple];
        // Untuk saat ini, jika tidak ada kolom idPrinciple, kita hitung semua produk
         return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
      }
    }
    
    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      columns: ['COUNT(*) as count'],
      where: whereClause,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Operasi Delete (Opsional) ---
  Future<void> deleteAll(String tableName) async {
    Database db = await instance.database;
    await db.delete(tableName);
  }

  Future<void> clearTableByArea(String tableName, String idArea) async {
    Database db = await instance.database;
    String columnNameToFilter = 'area'; // default untuk outlets
    if (tableName == 'kecamatans' || tableName == 'kelurahans') {
        columnNameToFilter = 'id_area';
    }
    // Tambahkan kondisi lain jika nama kolom id_area berbeda untuk tabel lain

    await db.delete(tableName, where: '$columnNameToFilter = ?', whereArgs: [idArea]);
  }
  
  // --- Ambil Data (Contoh untuk Area) ---
  Future<List<AreaModel>> getAreas({String? query}) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('areas',
          where: 'nama LIKE ? OR kodeArea LIKE ?',
          whereArgs: ['%$query%', '%$query%']);
    } else {
      maps = await db.query('areas');
    }
    if (maps.isNotEmpty) {
      return maps.map((map) => AreaModel.fromJson(map)).toList();
    } else {
      return [];
    }
  }

  Future<List<ProductModel>> getProductSearch({String? query, int limit = 10}) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('products',
          where: 'LOWER(nama) LIKE LOWER(?) OR LOWER(kode) LIKE LOWER(?)',
          whereArgs: ['%$query%', '%$query%'],
          limit: limit,
      );
    } else {
      maps = await db.query('products', limit: limit);
    }
    if (maps.isNotEmpty) {
      return maps.map((map) => ProductModel.fromJson(map)).toList();
    } else {
      return [];
    }
  }

  // METODE BARU: Mengambil semua data sales print out offline
  Future<List<Map<String, dynamic>>> getAllSalesPrintOuts() async {
    Database db = await instance.database;
    // Urutkan berdasarkan outlet dan periode agar pengelompokan lebih mudah di Dart
    return await db.query('sales_print_outs', orderBy: 'outlet ASC, periode ASC');
  }

  // METODE BARU: Menghapus data sales print out berdasarkan list ID
  Future<void> deleteSalesPrintOutsByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in ids) {
      batch.delete('sales_print_outs', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${ids.length} sales print outs from local DB.");
  }

  // --- Operasi untuk Open Ending Data ---
  Future<int> insertOpenEndingData(Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.insert('open_ending_data', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllOpenEndingData() async {
    Database db = await instance.database;
    return await db.query('open_ending_data', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> deleteOpenEndingDataByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in ids) {
      batch.delete('open_ending_data', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${ids.length} open ending data items from local DB.");
  }

  // Fungsi untuk memasukkan data POSM
  Future<int> insertPosmEntry(Map<String, dynamic> row) async {
    Database db = await instance.database;
    // Tambahkan timestamp saat ini
    row['is_synced'] = 0; // Tandai sebagai belum sinkron
    return await db.insert('posm_entries', row);
  }

  // Fungsi untuk mendapatkan semua data POSM yang belum sinkron (opsional, untuk mekanisme sinkronisasi)
  Future<List<Map<String, dynamic>>> getUnsyncedPosmEntries() async {
    Database db = await instance.database;
    return await db.query('posm_entries', where: 'is_synced = ?', whereArgs: [0]);
  }

  // Fungsi untuk menandai data POSM sebagai sudah sinkron (opsional)
  Future<int> markPosmEntryAsSynced(int id) async {
    Database db = await instance.database;
    return await db.update('posm_entries', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Mengambil semua POSM entries yang belum sinkron
  Future<List<Map<String, dynamic>>> getAllUnsyncedPosmEntries() async {
    Database db = await instance.database;
    return await db.query('posm_entries', where: 'is_synced = ?', whereArgs: [0], orderBy: 'outlet_name ASC, timestamp ASC');
  }

  // Menghapus POSM entries berdasarkan list ID lokal
  Future<void> deletePosmEntriesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in ids) {
      batch.delete('posm_entries', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${ids.length} POSM entries from local DB.");
  }

  Future<int> insertOOSItem(OOSItem oosItem) async {
    Database db = await instance.database;
    Map<String, dynamic> row = oosItem.toMapLocal();
    row.remove('local_id'); // Hapus local_id karena akan auto-increment
    final String currentTimestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    row['timestamp'] = currentTimestamp; // Tambah timestamp
    return await db.insert('oos_entries', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OOSItem>> getUnsyncedOOSItems() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oos_entries',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return OOSItem.fromMapLocal(maps[i]);
    });
  }

  Future<List<OOSItem>> getAllOOSItems() async { // Untuk halaman list offline
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oos_entries',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return OOSItem.fromMapLocal(maps[i]);
    });
  }


  Future<int> updateOOSItemSyncStatus(int localId, int isSynced) async {
    Database db = await instance.database;
    return await db.update(
      'oos_entries',
      {'is_synced': isSynced},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> deleteOOSItem(int localId) async {
    Database db = await instance.database;
    return await db.delete(
      'oos_entries',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteMultipleOOSItems(List<int> localIds) async {
    if (localIds.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in localIds) {
      batch.delete('oos_entries', where: 'local_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${localIds.length} OOS items from local DB.");
  }

  // --- Operasi untuk Activation Entries ---
  Future<int> insertActivationEntry(Map<String, dynamic> row) async {
    Database db = await instance.database;
    row['is_synced'] = 0; // Tandai sebagai belum sinkron
    return await db.insert('activation_entries', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedActivationEntries() async {
    Database db = await instance.database;
    return await db.query('activation_entries', where: 'is_synced = ?', whereArgs: [0], orderBy: 'outlet_name ASC, tgl ASC');
  }

  Future<void> deleteActivationEntriesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in ids) {
      batch.delete('activation_entries', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${ids.length} activation entries from local DB.");
  }

  // --- Operasi untuk Price Monitoring Entries ---
  Future<int> insertPriceMonitoringEntry(Map<String, dynamic> row) async {
    Database db = await instance.database;
    row['is_synced'] = 0; // Tandai sebagai belum sinkron
    return await db.insert('price_monitoring_entries', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPriceMonitoringEntries() async {
    Database db = await instance.database;
    return await db.query('price_monitoring_entries', where: 'is_synced = ?', whereArgs: [0], orderBy: 'outlet_name ASC, tgl ASC');
  }

  Future<void> deletePriceMonitoringEntriesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int id in ids) {
      batch.delete('price_monitoring_entries', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    print("Deleted ${ids.length} price monitoring entries from local DB.");
  }


}
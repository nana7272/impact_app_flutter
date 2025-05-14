import 'package:impact_app/screens/setting/model/area_model.dart';
import 'package:impact_app/screens/setting/model/kecamatan_model.dart';
import 'package:impact_app/screens/setting/model/kelurahan_model.dart';
import 'package:impact_app/screens/setting/model/outlet_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
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
      version: 8, // Naikkan versi karena ada tabel baru
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // << TAMBAHKAN INI
    );
  }

  // Tambahkan method _onUpgrade
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) { 
      //await db.execute('''
        //ALTER TABLE kelurahans ADD COLUMN id_area TEXT REFERENCES areas(idArea)
      //''');
      // Anda mungkin perlu mengisi nilai id_area untuk data lama jika memungkinkan,
      // tapi untuk kasus ini, data baru akan memilikinya.

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
    }
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE open_ending_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_principle INTEGER,
        id_outlet TEXT,
        id_product TEXT,
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
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE open_ending_data RENAME COLUMN expired_date TO expired
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        ALTER TABLE open_ending_data RENAME COLUMN return_qty TO return
      ''');
    }
  }

  Future _onCreate(Database db, int version) async {
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
        id_product TEXT,
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

  Future<List<ProductModel>> getProductSearch({String? query}) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('products',
          where: 'nama LIKE ? OR kode LIKE ?',
          whereArgs: ['%$query%', '%$query%']);
    } else {
      maps = await db.query('areas');
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

}
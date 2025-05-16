import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/setting/model/area_model.dart';
import 'package:impact_app/screens/setting/model/kecamatan_model.dart';
import 'package:impact_app/screens/setting/model/kelurahan_model.dart';
import 'package:impact_app/screens/setting/model/outlet_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


enum SyncStatus { idle, loadingAreas, searching, syncing, error, success }

class SyncProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  SharedPreferences? _prefs;

  List<AreaModel> _areas = [];
  List<AreaModel> _filteredAreas = [];
  AreaModel? _selectedArea;
  String _searchQuery = "";

  SyncStatus _areaStatus = SyncStatus.idle;
  SyncStatus _syncProcessStatus = SyncStatus.idle;
  String _errorMessage = "";
  String _successMessage = "";


  String _lastSyncTime = "Belum pernah";
  final int _idPrinciple = 1;

  // Progress variables
  double _outletProgress = 0.0;
  int _localOutletCount = 0;
  int _totalOutletApiCount = 0;

  double _productProgress = 0.0;
  int _localProductCount = 0;
  int _totalProductApiCount = 0;

  double _kecamatanProgress = 0.0;
  int _localKecamatanCount = 0;
  int _totalKecamatanApiCount = 0;

  double _kelurahanProgress = 0.0;
  int _localKelurahanCount = 0;
  int _totalKelurahanApiCount = 0;

  // Getters
  List<AreaModel> get filteredAreas => _filteredAreas;
  AreaModel? get selectedArea => _selectedArea;
  String get searchQuery => _searchQuery;
  SyncStatus get areaStatus => _areaStatus;
  SyncStatus get syncProcessStatus => _syncProcessStatus;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  String get lastSyncTime => _lastSyncTime;
  double get outletProgress => _outletProgress;
  int get localOutletCount => _localOutletCount;
  int get totalOutletApiCount => _totalOutletApiCount;
  // ... (getter lainnya untuk product, kecamatan, kelurahan)
  double get productProgress => _productProgress;
  int get localProductCount => _localProductCount;
  int get totalProductApiCount => _totalProductApiCount;

  double get kecamatanProgress => _kecamatanProgress;
  int get localKecamatanCount => _localKecamatanCount;
  int get totalKecamatanApiCount => _totalKecamatanApiCount;

  double get kelurahanProgress => _kelurahanProgress;
  int get localKelurahanCount => _localKelurahanCount;
  int get totalKelurahanApiCount => _totalKelurahanApiCount;


  SyncProvider() {
    _initPrefsAndLoadData();
  }

  Future<void> _initPrefsAndLoadData() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLastSyncTime();
    await fetchAreas();
    await _loadInitialDataCounts(); // Ini akan mencoba load selectedArea dari prefs
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredAreas = [];
      _areaStatus = SyncStatus.idle; // Atau status lain yang sesuai
    } else {
      _areaStatus = SyncStatus.searching;
      _filteredAreas = _areas
          .where((area) =>
              area.nama.toLowerCase().contains(query.toLowerCase()) ||
              area.kodeArea.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    print('[SyncProvider] setSearchQuery: query="$_searchQuery", _areas.length=${_areas.length}, _filteredAreas.length=${_filteredAreas.length}, status=$_areaStatus'); // DEBUG
  
    notifyListeners();
  }

  Future<void> fetchAreas() async {
    _areaStatus = SyncStatus.loadingAreas;
    notifyListeners();
    print('[SyncProvider] fetchAreas: Status changed to loadingAreas.'); // DEBUG

    try {
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/areas'), headers: Header.headget());
    print('[SyncProvider] fetchAreas: API Response Code: ${response.statusCode}'); // DEBUG

    if (response.statusCode == 200) {
      List<dynamic> areaData = json.decode(response.body);
      _areas = areaData.map((jsonMap) => AreaModel.fromJson(jsonMap)).toList();
      _areaStatus = SyncStatus.idle;
      print('[SyncProvider] fetchAreas SUCCESS: ${_areas.length} areas loaded.'); // DEBUG
      if (_areas.isEmpty) {
        print('[SyncProvider] fetchAreas WARNING: API returned 0 areas.'); // DEBUG
      }
    } else {
      _errorMessage = 'Gagal memuat area: ${response.statusCode}';
      _areaStatus = SyncStatus.error;
       _areas = []; // Pastikan _areas kosong jika error
      print('[SyncProvider] fetchAreas FAIL: Status Code ${response.statusCode}, Error: $_errorMessage'); // DEBUG
    }
  } catch (e) {
    _errorMessage = 'Error memuat area: $e';
    _areaStatus = SyncStatus.error;
    _areas = []; // Pastikan _areas kosong jika exception
    print('[SyncProvider] fetchAreas EXCEPTION: $e'); // DEBUG
  }
    notifyListeners();
  }

  Future<void> selectArea(AreaModel area) async {
    _selectedArea = area;
    _searchQuery = area.nama; // Update search query untuk ditampilkan di TextField
    _filteredAreas = []; // Kosongkan filter setelah dipilih
    _areaStatus = SyncStatus.idle; // Kembali ke idle atau status selected

    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setString('selectedAreaId', area.idArea);
    await _prefs!.setString('selectedAreaName', area.nama);
    await _prefs!.setString('selectedAreaCode', area.kodeArea);
    
    notifyListeners();
    await _loadInitialDataCounts(); // Muat data count untuk area baru
  }

  void clearSearch() {
    _searchQuery = "";
    _filteredAreas = [];
    // _selectedArea = null; // Opsional: reset selected area
    _areaStatus = SyncStatus.idle;
    notifyListeners();
    // _loadInitialDataCounts(); // Jika selected area direset, update counts
  }


  Future<void> _loadLastSyncTime() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    _lastSyncTime = _prefs!.getString('lastSyncTime') ?? "Belum pernah";
    notifyListeners();
  }

  Future<void> _saveLastSyncTime() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final formattedTime = DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(now);
    _lastSyncTime = formattedTime;
    await _prefs!.setString('lastSyncTime', formattedTime);
    notifyListeners();
  }

  Future<void> _loadInitialDataCounts() async {
    if (_selectedArea == null) {
        if (_prefs == null) _prefs = await SharedPreferences.getInstance();
        String? selectedAreaId = _prefs!.getString('selectedAreaId');
        String? selectedAreaName = _prefs!.getString('selectedAreaName');
        String? selectedAreaCode = _prefs!.getString('selectedAreaCode');

        if (selectedAreaId != null && selectedAreaName != null && selectedAreaCode != null) {
          _selectedArea = AreaModel(idArea: selectedAreaId, nama: selectedAreaName, kodeArea: selectedAreaCode);
          _searchQuery = _selectedArea!.nama; // Untuk konsistensi tampilan
        }
    }

    if (_selectedArea != null) {
      _localOutletCount = await _dbHelper.getCount('outlets', idArea: _selectedArea!.idArea);
      _localProductCount = await _dbHelper.getCount('products' /*, idPrinciple: _idPrinciple.toString()*/);
      _localKecamatanCount = await _dbHelper.getCount('kecamatans', idArea: _selectedArea!.idArea);
      _localKelurahanCount = await _dbHelper.getCount('kelurahans', idArea: _selectedArea!.idArea);

      if (_prefs == null) _prefs = await SharedPreferences.getInstance();
      _totalOutletApiCount = _prefs!.getInt('totalOutlet_${_selectedArea!.idArea}') ?? 0;
      _totalProductApiCount = _prefs!.getInt('totalProduct_${_idPrinciple}') ?? 0;
      _totalKecamatanApiCount = _prefs!.getInt('totalKecamatan_${_selectedArea!.idArea}') ?? 0;
      _totalKelurahanApiCount = _prefs!.getInt('totalKelurahan_${_selectedArea!.idArea}') ?? 0;
      
      _updateProgressUI();
    } else {
      // Reset counts jika tidak ada area terpilih
      _localOutletCount = 0; _totalOutletApiCount = 0;
      _localProductCount = 0; _totalProductApiCount = 0;
      // ... dan seterusnya
      _updateProgressUI();
    }
    notifyListeners();
  }
  
  void _updateProgressUI() {
    _outletProgress = (_totalOutletApiCount == 0) ? 0.0 : (_localOutletCount / _totalOutletApiCount);
    _productProgress = (_totalProductApiCount == 0) ? 0.0 : (_localProductCount / _totalProductApiCount);
    _kecamatanProgress = (_totalKecamatanApiCount == 0) ? 0.0 : (_localKecamatanCount / _totalKecamatanApiCount);
    _kelurahanProgress = (_totalKelurahanApiCount == 0) ? 0.0 : (_localKelurahanCount / _totalKelurahanApiCount);

    _outletProgress = _outletProgress.clamp(0.0, 1.0);
    _productProgress = _productProgress.clamp(0.0, 1.0);
    _kecamatanProgress = _kecamatanProgress.clamp(0.0, 1.0);
    _kelurahanProgress = _kelurahanProgress.clamp(0.0, 1.0);
    // notifyListeners(); // Dipanggil oleh method yang memanggil ini
  }

  Future<void> startSync() async {
    if (_selectedArea == null) {
      _errorMessage = 'Silakan pilih area terlebih dahulu.';
      _syncProcessStatus = SyncStatus.error;
      notifyListeners();
      return;
    }

    _syncProcessStatus = SyncStatus.syncing;
    _errorMessage = "";
    _successMessage = "";
    notifyListeners();

    // Bersihkan data lokal untuk area yang dipilih sebelum sinkronisasi baru
    // Ini penting jika tujuannya adalah "refresh" data.
    // Jika tujuannya "append", logika offset harus lebih kompleks.
    // Untuk kasus sinkronisasi dari nol atau refresh total per area:
    await _dbHelper.clearTableByArea('outlets', _selectedArea!.idArea);
    // Untuk produk, pertimbangkan apakah akan menghapus semua produk atau hanya yang terkait principle/area.
    // Jika produk bersifat global atau hanya per principle, jangan clear di sini kecuali itu strateginya.
    await _dbHelper.deleteAll('products'); // Contoh jika produk di-clear semua
    await _dbHelper.clearTableByArea('kecamatans', _selectedArea!.idArea);
    await _dbHelper.clearTableByArea('kelurahans', _selectedArea!.idArea);
    
    // Reset local counts di provider setelah clear DB
    _localOutletCount = 0;
    _localProductCount = await _dbHelper.getCount('products'); // Asumsi produk tidak di-clear per area, jadi ambil count yang ada. Jika di-clear, set ke 0.
    _localKecamatanCount = 0;
    _localKelurahanCount = 0;
    _updateProgressUI(); 
    notifyListeners();


    // --- BAGIAN LAMA YANG PERLU DIGANTI ---
    // Helper untuk memanggil sync per tipe dan menangani state
    // Future<void> _sync(String type) async {
    //     bool result = await _syncDataTypeRecursive(type, 0); // Mulai dengan offset 0 untuk tipe ini
    //     if (!result &&_syncProcessStatus != SyncStatus.error) { // Jika gagal tapi bukan karena error network/parsing sebelumnya
    //         _errorMessage = "Gagal menyelesaikan sinkronisasi untuk $type.";
    //         _syncProcessStatus = SyncStatus.error; // Set error jika ada kegagalan spesifik
    //     }
    //     notifyListeners(); // Update UI setelah setiap tipe data
    // }

    // --- PENGGANTI DENGAN SATU FUNGSI REKURSIF UTAMA ---
    Map<String, int> initialOffsets = {
      'outlet': 0, // Mulai dari 0 karena tabel sudah di-clear untuk area ini
      'product': _localProductCount, // Gunakan count yang ada jika produk tidak di-clear per area
      'kecamatan': 0,
      'kelurahan': 0,
    };

    bool syncSuccess = await _syncAllDataRecursively(initialOffsets);

    if (syncSuccess) {
      await _saveLastSyncTime();
      _successMessage = "Proses sinkronisasi selesai.";
      _syncProcessStatus = SyncStatus.success;
    } else {
      // _errorMessage sudah di-set oleh _syncAllDataRecursively jika ada error
      // Pastikan status error jika sync gagal dan belum ada pesan error spesifik
      if (_errorMessage.isEmpty) {
        _errorMessage = "Sinkronisasi gagal karena alasan yang tidak diketahui.";
      }
      _syncProcessStatus = SyncStatus.error;
    }
    notifyListeners();
  }

  // Fungsi rekursif yang lama, bisa dihapus atau dikomentari jika menggunakan _syncAllDataRecursively
  /*
  Future<bool> _syncDataTypeRecursive(String type, int currentOffsetForType) async {
    if (_selectedArea == null) return false;
    if (_syncProcessStatus == SyncStatus.error) return false; // Hentikan jika ada error global

    // Offset untuk tipe data lain bisa diambil dari DB atau di-nol-kan jika API tidak butuh semua offset setiap call
    // Untuk API ini, sepertinya semua offset dikirim setiap kali.
    Map<String, dynamic> requestBody = {
      "offset_outlet": await _dbHelper.getCount('outlets', idArea: _selectedArea!.idArea),
      "offset_product": await _dbHelper.getCount('products'),
      "offset_kecamatan": await _dbHelper.getCount('kecamatans', idArea: _selectedArea!.idArea),
      "offset_kelurahan": await _dbHelper.getCount('kelurahans', idArea: _selectedArea!.idArea),
      "id_area": int.parse(_selectedArea!.idArea),
      "id_principle": _idPrinciple
    };
    
    // Update offset untuk tipe yang sedang disinkronisasi secara rekursif
    if(type == 'outlet') requestBody['offset_outlet'] = currentOffsetForType;
    if(type == 'product') requestBody['offset_product'] = currentOffsetForType;
    if(type == 'kecamatan') requestBody['offset_kecamatan'] = currentOffsetForType;
    if(type == 'kelurahan') requestBody['offset_kelurahan'] = currentOffsetForType;


    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseApiUrl}/api/sync'),
        headers: Header.headpos(),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_prefs == null) _prefs = await SharedPreferences.getInstance();

        _totalOutletApiCount = data['total_all_outlet'] ?? _totalOutletApiCount;
        _totalProductApiCount = data['total_all_product'] ?? _totalProductApiCount;
        _totalKecamatanApiCount = data['total_all_kecamatan'] ?? _totalKecamatanApiCount;
        _totalKelurahanApiCount = data['total_all_kelurahan'] ?? _totalKelurahanApiCount;

        await _prefs!.setInt('totalOutlet_${_selectedArea!.idArea}', _totalOutletApiCount);
        await _prefs!.setInt('totalProduct_${_idPrinciple}', _totalProductApiCount);
        await _prefs!.setInt('totalKecamatan_${_selectedArea!.idArea}', _totalKecamatanApiCount);
        await _prefs!.setInt('totalKelurahan_${_selectedArea!.idArea}', _totalKelurahanApiCount);
        
        int NriteliveDataInBatch = 0;
        int currentLocalCountForType = 0;
        int totalApiForType = 0;

        if (type == 'outlet' && data['outlet'] != null) {
          List<OutletModel> items = (data['outlet'] as List).map((o) => OutletModel.fromJson(o)).toList();
          if (items.isNotEmpty) await _dbHelper.bulkInsertOutlets(items);
          _localOutletCount = await _dbHelper.getCount('outlets', idArea: _selectedArea!.idArea);
          NriteliveDataInBatch = items.length;
          currentLocalCountForType = _localOutletCount;
          totalApiForType = _totalOutletApiCount;
        } else if (type == 'product' && data['product'] != null) {
          List<ProductModel> items = (data['product'] as List).map((p) => ProductModel.fromJson(p)).toList();
          if (items.isNotEmpty) await _dbHelper.bulkInsertProducts(items);
          _localProductCount = await _dbHelper.getCount('products');
          NriteliveDataInBatch = items.length;
          currentLocalCountForType = _localProductCount;
          totalApiForType = _totalProductApiCount;
        } else if (type == 'kecamatan' && data['kecamatan'] != null) {
          List<KecamatanModel> items = (data['kecamatan'] as List).map((k) => KecamatanModel.fromJson(k)).toList();
          if (items.isNotEmpty) await _dbHelper.bulkInsertKecamatans(items);
          _localKecamatanCount = await _dbHelper.getCount('kecamatans', idArea: _selectedArea!.idArea);
          NriteliveDataInBatch = items.length;
          currentLocalCountForType = _localKecamatanCount;
          totalApiForType = _totalKecamatanApiCount;
        } else if (type == 'kelurahan' && data['kelurahan'] != null) {
          List<KelurahanModel> items = (data['kelurahan'] as List).map((l) => KelurahanModel.fromJson(l)).toList();
          if (items.isNotEmpty) await _dbHelper.bulkInsertKelurahans(items);
          _localKelurahanCount = await _dbHelper.getCount('kelurahans', idArea: _selectedArea!.idArea);
          NriteliveDataInBatch = items.length;
          currentLocalCountForType = _localKelurahanCount;
          totalApiForType = _totalKelurahanApiCount;
        }
        
        _updateProgressUI();
        notifyListeners();

        if (NriteliveDataInBatch > 0 && currentLocalCountForType < totalApiForType) {
          // Masih ada data, panggil rekursif dengan offset baru untuk TIPE INI SAJA
          return await _syncDataTypeRecursive(type, currentLocalCountForType);
        } else {
          return true; // Selesai untuk tipe ini (tidak ada data baru atau sudah semua)
        }
      } else {
        _errorMessage = 'Gagal sinkronisasi $type (Batch): ${response.statusCode} - ${response.body}';
        _syncProcessStatus = SyncStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error sinkronisasi $type (Batch): $e';
      _syncProcessStatus = SyncStatus.error;
      notifyListeners();
      return false;
    }
  }
  */

  // Fungsi rekursif baru yang menangani semua tipe data sekaligus
  Future<bool> _syncAllDataRecursively(Map<String, int> currentOffsets) async {
    if (_selectedArea == null) { // Seharusnya sudah dicek di startSync
      _errorMessage = "Area belum dipilih untuk sinkronisasi.";
      _syncProcessStatus = SyncStatus.error;
      // notifyListeners(); // startSync akan memanggil notifyListeners
      return false;
    }
    // Hentikan jika sudah ada error dari iterasi sebelumnya atau proses lain
    if (_syncProcessStatus == SyncStatus.error && _errorMessage.isNotEmpty) {
        return false;
    }

    Map<String, dynamic> requestBody = {
      "offset_outlet": currentOffsets['outlet'],
      "offset_product": currentOffsets['product'],
      "offset_kecamatan": currentOffsets['kecamatan'],
      "offset_kelurahan": currentOffsets['kelurahan'],
      "id_area": int.parse(_selectedArea!.idArea),
      "id_principle": _idPrinciple
    };

    print("[SyncProvider] Requesting API with offsets: $requestBody");

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseApiUrl}/api/sync'), // Pastikan URL benar
        headers: Header.headpos(), // Pastikan Header.headpos() ada dan mengembalikan header yang benar
        body: json.encode(requestBody),
      );

      print("[SyncProvider] API Response Code: ${response.statusCode}");
      // print("[SyncProvider] API Response Body: ${response.body}"); // Hati-hati jika body besar

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_prefs == null) _prefs = await SharedPreferences.getInstance();

        // Selalu update total counts dari API jika ada
        _totalOutletApiCount = data['total_all_outlet'] ?? _totalOutletApiCount;
        _totalProductApiCount = data['total_all_product'] ?? _totalProductApiCount;
        _totalKecamatanApiCount = data['total_all_kecamatan'] ?? _totalKecamatanApiCount;
        _totalKelurahanApiCount = data['total_all_kelurahan'] ?? _totalKelurahanApiCount;

        await _prefs!.setInt('totalOutlet_${_selectedArea!.idArea}', _totalOutletApiCount);
        await _prefs!.setInt('totalProduct_${_idPrinciple}', _totalProductApiCount);
        await _prefs!.setInt('totalKecamatan_${_selectedArea!.idArea}', _totalKecamatanApiCount);
        await _prefs!.setInt('totalKelurahan_${_selectedArea!.idArea}', _totalKelurahanApiCount);
        
        bool anyDataReceivedInThisBatch = false;

        if (data['outlet'] != null && (data['outlet'] as List).isNotEmpty) {
          List<OutletModel> items = (data['outlet'] as List).map((o) => OutletModel.fromJson(o)).toList();
          await _dbHelper.bulkInsertOutlets(items);
          _localOutletCount += items.length; // Tambahkan jumlah item yang baru diterima
          currentOffsets['outlet'] = _localOutletCount; // Update offset untuk panggilan berikutnya
          anyDataReceivedInThisBatch = true;
          print("[SyncProvider] Synced ${items.length} outlets. New local count: $_localOutletCount");
        }

        if (data['product'] != null && (data['product'] as List).isNotEmpty) {
          List<ProductModel> items = (data['product'] as List).map((p) => ProductModel.fromJson(p)).toList();
          await _dbHelper.bulkInsertProducts(items);
          _localProductCount += items.length;
          currentOffsets['product'] = _localProductCount;
          anyDataReceivedInThisBatch = true;
          print("[SyncProvider] Synced ${items.length} products. New local count: $_localProductCount");
        }

        if (data['kecamatan'] != null && (data['kecamatan'] as List).isNotEmpty) {
          List<KecamatanModel> items = (data['kecamatan'] as List).map((k) => KecamatanModel.fromJson(k)).toList();
          await _dbHelper.bulkInsertKecamatans(items);
          _localKecamatanCount += items.length;
          currentOffsets['kecamatan'] = _localKecamatanCount;
          anyDataReceivedInThisBatch = true;
          print("[SyncProvider] Synced ${items.length} kecamatans. New local count: $_localKecamatanCount");
        }

        if (data['kelurahan'] != null && (data['kelurahan'] as List).isNotEmpty) {
          List<KelurahanModel> items = (data['kelurahan'] as List).map((l) => KelurahanModel.fromJson(l)).toList();
          await _dbHelper.bulkInsertKelurahans(items);
          _localKelurahanCount += items.length;
          currentOffsets['kelurahan'] = _localKelurahanCount;
          anyDataReceivedInThisBatch = true;
          print("[SyncProvider] Synced ${items.length} kelurahans. New local count: $_localKelurahanCount");
        }
        
        _updateProgressUI();
        notifyListeners();

        bool moreDataExpected = (_localOutletCount < _totalOutletApiCount) ||
                                (_localProductCount < _totalProductApiCount) ||
                                (_localKecamatanCount < _totalKecamatanApiCount) ||
                                (_localKelurahanCount < _totalKelurahanApiCount);

        if (anyDataReceivedInThisBatch && moreDataExpected) {
          print("[SyncProvider] More data expected. Calling API again with new offsets: $currentOffsets");
          return await _syncAllDataRecursively(currentOffsets);
        } else {
          if (!anyDataReceivedInThisBatch && moreDataExpected) {
              print("[SyncProvider] WARNING: No data received in this batch, but more data is expected. Stopping to prevent infinite loop. Check API response and local counts. Totals: Outlets(${_totalOutletApiCount}), Products(${_totalProductApiCount}), etc.");
              _errorMessage = "Sinkronisasi berhenti: API tidak mengirim data baru meskipun data lokal (${_localOutletCount}/${_totalOutletApiCount} outlets, dll.) belum lengkap.";
              _syncProcessStatus = SyncStatus.error;
              // notifyListeners(); // Akan dipanggil oleh startSync
              return false; 
          }
          print("[SyncProvider] Sync completed for this batch or all data synced.");
          return true;
        }
      } else {
        _errorMessage = 'Gagal sinkronisasi (API Error): ${response.statusCode} - ${response.body}';
        _syncProcessStatus = SyncStatus.error;
        // notifyListeners(); // Akan dipanggil oleh startSync
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error saat sinkronisasi: $e';
      _syncProcessStatus = SyncStatus.error;
      // notifyListeners(); // Akan dipanggil oleh startSync
      return false;
    }
  }

  bool get isLoadingAreas => _areaStatus == SyncStatus.loadingAreas; // Getter untuk status loading area
bool get hasSuccessfullyFetchedAreas => _areaStatus == SyncStatus.idle && _areas.isNotEmpty;
bool get hasFailedToFetchAreas => _areaStatus == SyncStatus.error; // Lebih sederhana, jika status error berarti fetch gagal


  void clearMessages() {
    _errorMessage = "";
    _successMessage = "";
    // Tidak perlu notifyListeners() di sini jika ini hanya untuk mencegah snackbar muncul berulang kali
    // pada rebuild yang tidak terkait langsung dengan penyelesaian operasi.
    // Jika Anda ingin UI bereaksi terhadap penghapusan pesan, maka panggil notifyListeners().
  }
}
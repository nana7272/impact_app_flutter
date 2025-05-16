// lib/screens/product/posm/posm_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/product/posm/api/posm_api_service.dart';
import 'package:impact_app/screens/product/posm/model/posm_models.dart';
import 'package:impact_app/screens/setting/model/outlet_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/session_manager.dart'; // Import SessionManager
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart'; // Import Logger

class PosmScreen extends StatefulWidget {
  final String storeId; // Ini adalah idOutlet
  final String visitId;

  const PosmScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<PosmScreen> createState() => _PosmScreenState();
}

class _PosmScreenState extends State<PosmScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final Logger _logger = Logger(); // Tambahkan Logger
  final String _tag = 'PosmScreen'; // Tag untuk logging

  final List<POSMItem> _posmItems = [];
  final PosmApiService _apiService = PosmApiService();
  List<PosmType> _posmTypes = [];
  List<PosmStatus> _posmStatusOptions = [];
  Store? _currentOutlet; // Untuk menyimpan data outlet

  @override
  void initState() {
    super.initState();
    _loadCurrentOutletData(); // Muat data outlet
    _addNewPOSMItem();
    _fetchDropdownData();
  }

  Future<void> _loadCurrentOutletData() async {
    _currentOutlet = await SessionManager().getStoreData();
    if (_currentOutlet == null) {
      _logger.e(_tag, "Gagal memuat data outlet dari session untuk storeId: ${widget.storeId}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data toko. Fungsi offline mungkin terpengaruh.')),
        );
      }
    } else {
       _logger.d(_tag, "Outlet data loaded: ${_currentOutlet?.nama}");
       if(mounted) setState(() {}); // Untuk update UI jika nama toko ditampilkan
    }
  }


  Future<void> _fetchDropdownData() async {
    // ... (implementasi yang sudah ada)
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      bool hasInternet = await ConnectivityUtils.checkInternetConnection();
      if (hasInternet) {
        _posmTypes = await _apiService.getPosmTypes();
        _posmStatusOptions = await _apiService.getPosmStatus();
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada koneksi internet. Data dropdown mungkin tidak terbaru.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengambil data dropdown: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _addNewPOSMItem() {
    // ... (implementasi yang sudah ada)
    if (!mounted) return;
    setState(() { _posmItems.add(POSMItem()); });
  }

  void _removePOSMItem(int index) {
    // ... (implementasi yang sudah ada)
     if (_posmItems.length > 1) {
      if (!mounted) return;
      setState(() { _posmItems.removeAt(index); });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal harus ada 1 item POSM')));
    }
  }

  Future<void> _pickImage(int index) async {
    // ... (implementasi yang sudah ada)
     try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 30);
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() { _posmItems[index].image = File(pickedFile.path); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengambil gambar: $e')));
    }
  }

  bool _validateData() {
    // ... (implementasi yang sudah ada)
     for (int i = 0; i < _posmItems.length; i++) {
      final item = _posmItems[i];
      if (item.image == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon ambil foto untuk POSM item ${i + 1}')));
        return false;
      }
      if (item.type.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon pilih POSM Type untuk item ${i + 1}')));
        return false;
      }
      if (item.status.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon pilih POSM Status untuk item ${i + 1}')));
        return false;
      }
      if (item.installed.isEmpty || (int.tryParse(item.installed) ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi jumlah POSM Terpasang (>0) untuk item ${i + 1}')));
        return false;
      }
      if (item.note.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi POSM Keterangan untuk item ${i + 1}')));
        return false;
      }
    }
    return true;
  }

  void _showSendDataDialog() {
    // ... (implementasi yang sudah ada)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _submitData(false); }, // offline
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(25)),
              child: const Text('Offline (Local)'),
            ),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _submitData(true); }, // online
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(color: Colors.blue[300], borderRadius: BorderRadius.circular(25)),
              child: const Text('Online (Server)', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitData(bool isOnline) async {
    if (!_validateData()) return;
    if (_currentOutlet == null && !isOnline) { // Perlu data outlet untuk simpan nama outlet offline
        _logger.e(_tag, "Outlet data is null, cannot save outlet name for offline mode.");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data toko tidak termuat. Tidak bisa menyimpan nama toko untuk mode offline.')));
        // Pertimbangkan apakah akan melanjutkan tanpa nama toko atau menghentikan
        // Untuk saat ini, kita lanjutkan, tapi nama toko akan null di DB.
    }


    if (!mounted) return;
    setState(() { _isLoading = true; });
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final user = await SessionManager().getCurrentUser();
      final String userId = user?.idLogin ?? '1'; // Default '1' jika null
      final String principleId = user?.idpriciple ?? '1'; // Default '1' jika null


      if (isOnline) {
        bool hasInternet = await ConnectivityUtils.checkInternetConnection();
        if (!hasInternet) {
          Navigator.pop(context); 
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada koneksi internet. Silakan gunakan mode offline.')));
          setState(() { _isLoading = false; });
          return;
        }

        List<Map<String, String>> entries = [];
        List<File> imageFilesList = []; 

        for (var item in _posmItems) {
          entries.add({
            'id_user': userId,
            'id_pinciple': principleId,
            'id_outlet': widget.storeId,
            'type': item.typeId.isNotEmpty ? item.typeId : item.type,
            'posm_status': item.statusId.isNotEmpty ? item.statusId : item.status,
            'quantity': item.installed,
            'ket': item.note,
          });
          if (item.image != null) imageFilesList.add(item.image!);
        }

        bool success = await _apiService.submitPosmData(posmEntries: entries, imageFiles: imageFilesList);
        Navigator.pop(context); 

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dikirim ke server')));
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim data ke server. Data disimpan lokal.')));
          await _saveDataLocally(userId, principleId); // Berikan userId dan principleId
        }

      } else { // Offline
        await _saveDataLocally(userId, principleId); // Berikan userId dan principleId
        Navigator.pop(context); 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan secara lokal')));
        Navigator.pop(context); 
      }
    } catch (e) {
      Navigator.pop(context); 
      _logger.e(_tag, "Error submitting data: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e. Data disimpan lokal jika memungkinkan.')));
      if(isOnline) { 
        final user = await SessionManager().getCurrentUser();
        final String userId = user?.idLogin ?? '1';
        final String principleId = user?.idpriciple ?? '1';
        await _saveDataLocally(userId, principleId);
      }
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  // Modifikasi _saveDataLocally untuk menerima userId dan principleId
  Future<void> _saveDataLocally(String userId, String principleId) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    int successCount = 0;
    //String currentTimestamp = DateTime.now().toIso8601String();
    final String currentTimestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String outletName = _currentOutlet?.nama ?? 'Outlet Tidak Diketahui'; // Ambil nama outlet

    for (var item in _posmItems) {
      Map<String, dynamic> posmData = {
        'id_user': userId,
        'id_pinciple': principleId,
        'id_outlet': widget.storeId,
        'outlet_name': outletName, // SIMPAN NAMA OUTLET
        'visit_id': widget.visitId,
        'type': item.typeId.isNotEmpty ? item.typeId : item.type, 
        'posm_status': item.statusId.isNotEmpty ? item.statusId : item.status, 
        'quantity': int.tryParse(item.installed) ?? 0,
        'ket': item.note,
        'image_path': item.image?.path,
        'timestamp': currentTimestamp, 
        'is_synced': 0, 
      };
      try {
        await dbHelper.insertPosmEntry(posmData);
        successCount++;
      } catch (dbError) {
        _logger.e(_tag, "Error saving POSM item locally: $dbError, data: $posmData");
      }
    }
    // Pesan sukses/gagal sudah dihandle di _submitData
  }

  @override
  Widget build(BuildContext context) {
    // ... (implementasi UI yang sudah ada)
    // Pastikan menampilkan _currentOutlet?.nama jika tidak null
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input POSM'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: AppColors.primary, 
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _isLoading ? null : _showSendDataDialog, tooltip: 'Simpan Data')
        ],
      ),
      body: _isLoading && _posmTypes.isEmpty && _posmStatusOptions.isEmpty 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, color: AppColors.secondary, size: 30), 
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _currentOutlet?.nama ?? 'Outlet ID: ${widget.storeId}', // Tampilkan nama outlet jika ada
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), 
                    shrinkWrap: true,
                    itemCount: _posmItems.length,
                    itemBuilder: (context, index) {
                      return _buildPOSMItemWidget(index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addNewPOSMItem,
        backgroundColor: AppColors.accent, 
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Item POSM',
      ),
    );
  }

  Widget _buildPOSMItemWidget(int index) {
    // ... (implementasi UI per item yang sudah ada)
    final item = _posmItems[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(index),
                  child: Container(
                    height: 180, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: item.image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(item.image!, fit: BoxFit.cover, width: double.infinity))
                        : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]), const SizedBox(height: 8), const Text('Ambil Foto', style: TextStyle(color: Colors.grey))]))
                  ),
                ),
                if (_posmItems.length > 1) 
                  Positioned(
                    right: 4, top: 4,
                    child: Material(color: Colors.black54, shape: const CircleBorder(), child: InkWell(onTap: () => _removePOSMItem(index), customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.close, size: 18, color: Colors.white)))),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdownField<String>(
              label: 'POSM TYPE', value: item.type.isNotEmpty ? item.type : null, hint: 'Pilih Tipe POSM',
              items: _posmTypes.map((PosmType type) => DropdownMenuItem<String>(value: type.nama, child: Text(type.nama))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() { item.type = value; final selectedType = _posmTypes.firstWhere((t) => t.nama == value, orElse: () => PosmType(id: '', nama: '')); item.typeId = selectedType.id; });
              },
            ),
            const SizedBox(height: 12),
            _buildDropdownField<String>(
              label: 'POSM STATUS', value: item.status.isNotEmpty ? item.status : null, hint: 'Pilih Status POSM',
              items: _posmStatusOptions.map((PosmStatus status) => DropdownMenuItem<String>(value: status.nama, child: Text(status.nama))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() { item.status = value; final selectedStatus = _posmStatusOptions.firstWhere((s) => s.nama == value, orElse: () => PosmStatus(id: '', nama: '')); item.statusId = selectedStatus.id; });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(label: 'POSM TERPASANG (Qty)', initialValue: item.installed, hint: 'Jumlah terpasang', keyboardType: TextInputType.number, onChanged: (value) { item.installed = value; }),
            const SizedBox(height: 12),
            _buildTextField(label: 'POSM KETERANGAN', initialValue: item.note, hint: 'Masukkan keterangan', maxLines: 2, onChanged: (value) { item.note = value; }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({ required String label, required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    // ... (implementasi yang sudah ada)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), isDense: true),
          isExpanded: true, value: value, items: items, onChanged: onChanged, validator: (val) => (val == null) ? 'Field ini tidak boleh kosong' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({ required String label, String? initialValue, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1, required ValueChanged<String> onChanged}) {
    // ... (implementasi yang sudah ada)
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), isDense: true),
          keyboardType: keyboardType, maxLines: maxLines, onChanged: onChanged, validator: (val) => (val == null || val.isEmpty) ? 'Field ini tidak boleh kosong' : null,
        ),
      ],
    );
  }
}

// Model POSMItem tetap sama seperti di file Anda
class POSMItem {
  File? image;
  String type = ''; 
  String typeId = ''; 
  String status = ''; 
  String statusId = ''; 
  String installed = ''; 
  String note = '';

  POSMItem({
    this.image,
    this.type = '',
    this.typeId = '',
    this.status = '',
    this.statusId = '',
    this.installed = '',
    this.note = '',
  });
}

// lib/screens/sampling_konsumen_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/screens/product/sampling_konsument/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/form_validator.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';

class SamplingKonsumenScreen extends StatefulWidget {
  const SamplingKonsumenScreen({
    Key? key, 
  }) : super(key: key);

  @override
  State<SamplingKonsumenScreen> createState() => _SamplingKonsumenScreenState();
}

class _SamplingKonsumenScreenState extends State<SamplingKonsumenScreen> {
  final _formKey = GlobalKey<FormState>();
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  final Logger _logger = Logger();
  final String _tag = "SamplingKonsumenScreen";
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _kuantitasController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  
  // Controllers untuk pencarian produk
  final TextEditingController _produkSebelumnyaController = TextEditingController();
  final TextEditingController _produkYangDibeliController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSearchingSebelumnya = false;
  bool _isSearchingDibeli = false;
  
  List<ProductModel> _produkSebelumnyaResults = [];
  List<ProductModel> _produkYangDibeliResults = [];
  
  ProductModel? _selectedProdukSebelumnya;
  ProductModel? _selectedProdukYangDibeli;

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    _umurController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _produkSebelumnyaController.dispose();
    _produkYangDibeliController.dispose();
    _kuantitasController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
  
  // Pencarian produk sebelumnya
  Future<void> _searchProdukSebelumnya(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _produkSebelumnyaResults = [];
        _isSearchingSebelumnya = false;
      });
      return;
    }

    setState(() {
      _isSearchingSebelumnya = true;
    });

    try {
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword);
      setState(() {
        _produkSebelumnyaResults = products;
        _isSearchingSebelumnya = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingSebelumnya = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencari produk: $e')),
      );
    }
  }
  
  // Pencarian produk yang dibeli
  Future<void> _searchProdukYangDibeli(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _produkYangDibeliResults = [];
        _isSearchingDibeli = false;
      });
      return;
    }

    setState(() {
      _isSearchingDibeli = true;
    });

    try {
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword);
      setState(() {
        _produkYangDibeliResults = products;
        _isSearchingDibeli = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingDibeli = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencari produk: $e')),
      );
    }
  }
  
  // Memilih produk sebelumnya
  void _selectProdukSebelumnya(ProductModel produk) {
    setState(() {
      _selectedProdukSebelumnya = produk;
      _produkSebelumnyaController.text = produk.nama;
      _produkSebelumnyaResults = [];
    });
  }
  
  // Memilih produk yang dibeli
  void _selectProdukYangDibeli(ProductModel produk) {
    setState(() {
      _selectedProdukYangDibeli = produk;
      _produkYangDibeliController.text = produk.nama;
      _produkYangDibeliResults = [];
    });
  }
  
  // Reset form
  void _resetForm() {
    _namaController.clear();
    _noHpController.clear();
    _umurController.clear();
    _alamatController.clear();
    _emailController.clear();
    _produkSebelumnyaController.clear();
    _produkYangDibeliController.clear();
    _kuantitasController.clear();
    _keteranganController.clear();
    setState(() {
      _selectedProdukSebelumnya = null;
      _selectedProdukYangDibeli = null;
      _formKey.currentState?.reset();
    });
  }
  
  // Validasi form dan persiapan data
  
  // Dialog konfirmasi pengiriman data
  void _showSendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitDataOffline();
            },
            child: const Text('Offline (Simpan Lokal)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitDataOnline();
            },
            child: const Text('Online (Kirim ke Server)'),
          ),
        ],
      ),
    );
  }
  
  // Submit data online
  Future<void> _submitDataOnline() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi semua data yang diperlukan.')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
      );
      return;
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data...")])),
      );
    }
    
    try {
      final user = await SessionManager().getCurrentUser();
      final store = await SessionManager().getStoreData();

      if (user == null || user.idLogin == null || store == null || store.idOutlet == null) {
        throw Exception("Data user atau toko tidak lengkap.");
      }

      final data = SamplingKonsumenModel(
        nama: _namaController.text,
        alamat: _alamatController.text,
        noHp: _noHpController.text,
        umur: int.tryParse(_umurController.text) ?? 0,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        idOutlet: int.tryParse(store.idOutlet!) ?? 0,
        sender: int.tryParse(user.idLogin!) ?? 0,
        idProduct: int.tryParse(_selectedProdukYangDibeli!.idProduk!) ?? 0,
        idProductPrev: _selectedProdukSebelumnya != null ? int.tryParse(_selectedProdukSebelumnya!.idProduk!) : null,
        qlt: int.tryParse(_kuantitasController.text) ?? 0,
        keterangan: _keteranganController.text.isEmpty ? null : _keteranganController.text,
      );

      bool success = await _apiService.submitSamplingKonsumen(data);
      if(mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dikirim ke server')));
          _resetForm();
          // Optionally pop screen if submission means task is done
          Navigator.pop(context); 
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim data ke server')));
      }
    } catch (e) {
      _logger.e(_tag, "Error sending online: $e");
      if(mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Submit data offline
  Future<void> _submitDataOffline() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi semua data yang diperlukan.')));
      return;
    }

    setState(() => _isLoading = true);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Menyimpan data...")])),
      );
    }
    
    try {
      final user = await SessionManager().getCurrentUser();
      final store = await SessionManager().getStoreData();

      if (user == null || user.idLogin == null || store == null || store.idOutlet == null) {
        throw Exception("Data user atau toko tidak lengkap.");
      }

      final Map<String, dynamic> dataToSave = {
        'id_user': user.idLogin,
        'id_outlet': store.idOutlet,
        'outlet_name': store.nama,
        'nama_konsumen': _namaController.text,
        'alamat_konsumen': _alamatController.text,
        'no_hp_konsumen': _noHpController.text,
        'umur_konsumen': int.tryParse(_umurController.text) ?? 0,
        'email_konsumen': _emailController.text.isEmpty ? null : _emailController.text,
        'id_product_dibeli': _selectedProdukYangDibeli!.idProduk,
        'nama_product_dibeli': _selectedProdukYangDibeli!.nama,
        'id_product_sebelumnya': _selectedProdukSebelumnya?.idProduk,
        'nama_product_sebelumnya': _selectedProdukSebelumnya?.nama,
        'kuantitas': int.tryParse(_kuantitasController.text) ?? 0,
        'keterangan': _keteranganController.text.isEmpty ? null : _keteranganController.text,
        'tgl_submission': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      bool success = await _apiService.saveSamplingKonsumenOffline(dataToSave);
      if(mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan secara lokal')));
          _resetForm();
          // Optionally pop screen
          Navigator.pop(context);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan data secara lokal')));
      }
    } catch (e) {
      _logger.e(_tag, "Error saving offline: $e");
      if(mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampling Konsumen'),
        backgroundColor: Colors.grey[700],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // Form content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  const Text('Nama'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Nama',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => FormValidator.validateRequired(value, 'Nama'),
                  ),
                  const SizedBox(height: 16),
                  
                  // No HP
                  const Text('No HP'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noHpController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan No.HP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => FormValidator.validatePhone(value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Umur
                  const Text('Umur'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _umurController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Umur',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => FormValidator.validateRequired(value, 'Umur'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Alamat
                  const Text('Alamat'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _alamatController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Alamat',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) => FormValidator.validateRequired(value, 'Alamat'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Customer
                  const Text('Email Customer'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => FormValidator.validateEmail(value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Produk Sebelumnya dengan Search
                  const Text('Produk Sebelumnya'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: _produkSebelumnyaController,
                          decoration: InputDecoration(
                            hintText: 'Cari Produk',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _produkSebelumnyaController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _produkSebelumnyaController.clear();
                                        _selectedProdukSebelumnya = null;
                                        _produkSebelumnyaResults = [];
                                      });
                                    },
                                  )
                                : const Icon(Icons.clear, color: Colors.transparent),
                          ),
                          onChanged: _searchProdukSebelumnya,
                        ),
                      ),
                      if (_isSearchingSebelumnya)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_produkSebelumnyaResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _produkSebelumnyaResults.length,
                            itemBuilder: (context, index) {
                              final produk = _produkSebelumnyaResults[index];
                              return ListTile(
                                title: Text(produk.nama),
                                subtitle: produk.kode != null ? Text(produk.kode!) : null,
                                onTap: () => _selectProdukSebelumnya(produk),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Produk yang dibeli dengan Search
                  const Text('Produk yang dibeli'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: _produkYangDibeliController,
                          decoration: InputDecoration(
                            hintText: 'Cari Produk',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _produkYangDibeliController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _produkYangDibeliController.clear();
                                        _selectedProdukYangDibeli = null;
                                        _produkYangDibeliResults = [];
                                      });
                                    },
                                  )
                                : const Icon(Icons.clear, color: Colors.transparent),
                          ),
                          onChanged: _searchProdukYangDibeli,
                          validator: (value) => value == null || value.isEmpty || _selectedProdukYangDibeli == null 
                              ? 'Produk harus dipilih' 
                              : null,
                        ),
                      ),
                      if (_isSearchingDibeli)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_produkYangDibeliResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _produkYangDibeliResults.length,
                            itemBuilder: (context, index) {
                              final produk = _produkYangDibeliResults[index];
                              return ListTile(
                                title: Text(produk.nama),
                                subtitle: produk.kode != null ? Text(produk.kode!) : null,
                                onTap: () => _selectProdukYangDibeli(produk),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Kuantitas
                  const Text('Kuantitas'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kuantitasController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan kuantitas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => FormValidator.validateRequired(value, 'Kuantitas'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Keterangan
                  const Text('Keterangan'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Keterangan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // FAB for quick submission
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _isLoading ? null : _showSendDialog,
                heroTag: 'sampling_konsumen_fab', // Tambahkan heroTag unik
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
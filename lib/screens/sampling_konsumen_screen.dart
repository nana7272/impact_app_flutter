// lib/screens/sampling_konsumen_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/form_validator.dart';
import 'package:impact_app/utils/connectivity_utils.dart';

class SamplingKonsumenScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  final Store? store;
  
  const SamplingKonsumenScreen({
    Key? key, 
    required this.storeId, 
    required this.visitId,
    this.store,
  }) : super(key: key);

  @override
  State<SamplingKonsumenScreen> createState() => _SamplingKonsumenScreenState();
}

class _SamplingKonsumenScreenState extends State<SamplingKonsumenScreen> {
  final _formKey = GlobalKey<FormState>();
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  
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
  
  List<ProdukSampling> _produkSebelumnyaResults = [];
  List<ProdukSampling> _produkYangDibeliResults = [];
  
  ProdukSampling? _selectedProdukSebelumnya;
  ProdukSampling? _selectedProdukYangDibeli;

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
      final products = await _apiService.searchProduk(keyword);
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
      final products = await _apiService.searchProduk(keyword);
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
  void _selectProdukSebelumnya(ProdukSampling produk) {
    setState(() {
      _selectedProdukSebelumnya = produk;
      _produkSebelumnyaController.text = produk.nama;
      _produkSebelumnyaResults = [];
    });
  }
  
  // Memilih produk yang dibeli
  void _selectProdukYangDibeli(ProdukSampling produk) {
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
    });
  }
  
  // Validasi form dan persiapan data
  SamplingKonsumen? _prepareData() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }
    
    // Prepare kuantitas
    int kuantitas = 0;
    if (_kuantitasController.text.isNotEmpty) {
      kuantitas = int.tryParse(_kuantitasController.text) ?? 0;
    }
    
    return SamplingKonsumen(
      storeId: widget.storeId,
      visitId: widget.visitId,
      nama: _namaController.text,
      noHp: _noHpController.text,
      umur: _umurController.text,
      alamat: _alamatController.text,
      email: _emailController.text,
      produkSebelumnya: _selectedProdukSebelumnya?.id,
      produkYangDibeli: _selectedProdukYangDibeli?.id,
      kuantitas: kuantitas,
      keterangan: _keteranganController.text,
    );
  }
  
  // Dialog konfirmasi pengiriman data
  void _showSendDialog() {
    final samplingData = _prepareData();
    if (samplingData == null) {
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitDataOffline(samplingData);
            },
            child: const Text('Offline (Local)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitDataOnline(samplingData);
            },
            child: const Text('Online (Server)'),
          ),
        ],
      ),
    );
  }
  
  // Submit data online
  Future<void> _submitDataOnline(SamplingKonsumen data) async {
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
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      bool success = await _apiService.submitSamplingKonsumen(data);
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dikirim ke server')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim data ke server')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  // Submit data offline
  Future<void> _submitDataOffline(SamplingKonsumen data) async {
    setState(() => _isLoading = true);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      bool success = await _apiService.saveSamplingKonsumenOffline(data);
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    
    setState(() => _isLoading = false);
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
                  
                  // Submit button
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80), // Give space for the FAB
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showSendDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'SIMPAN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // FAB for quick submission
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _isLoading ? null : _showSendDialog,
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
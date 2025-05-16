import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/product/price_monitoring/api/price_monitoring_api_service.dart';
import 'package:impact_app/screens/product/price_monitoring/model/price_monitoring_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';
import '../../../themes/app_colors.dart';
import '../../../utils/connectivity_utils.dart';
import '../../../widget/search_bar_widget.dart';

class PriceMonitoringScreen extends StatefulWidget {
  
  const PriceMonitoringScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PriceMonitoringScreen> createState() => _PriceMonitoringScreenState();
}

class _PriceMonitoringScreenState extends State<PriceMonitoringScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PriceMonitoringApiService _apiService = PriceMonitoringApiService(); // Gunakan service baru
  final Logger _logger = Logger();
  final String _tag = 'PriceMonitoringScreen';
  
  bool _isLoading = false;
  bool _isSearching = false;
  Store? _currentOutlet; // Untuk menyimpan data outlet dari session
  List<ProductModel> _searchResults = [];
  List<PriceItem> _priceItems = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    for (var item in _priceItems) {
      item.normalPriceController.dispose();
      item.promoPriceController.dispose();
      item.notesController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOutletData(); // Panggil method untuk memuat data outlet
  }
  
  // Pencarian produk
  Future<void> _searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword, limit: 15); // Batasi hasil
      setState(() {
        _searchResults = products;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mencari produk: $e')),
        );
      }
    }
  }

  Future<void> _loadOutletData() async {
    _currentOutlet = await SessionManager().getStoreData();
    if (_currentOutlet == null) {
      _logger.e(_tag, "Gagal memuat data outlet dari session.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data toko. Silakan coba lagi.')),
        );
        // Opsi: Navigator.pop(context); // Kembali jika data toko penting
      }
    }
  }
  
  // Menambahkan produk ke list
  void _addProduct(ProductModel product) {
    // Periksa apakah produk sudah ada di list
    final existingIndex = _priceItems.indexWhere((p) => p.product.idProduk == product.idProduk);
    if (existingIndex >= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk sudah ditambahkan')),
        );
      }
      return;
    }
    
    // Tambahkan product dengan controller baru
    setState(() {
      _priceItems.add(PriceItem(
        product: product,
        normalPriceController: TextEditingController(text: product.harga ?? ''), // Menggunakan harga dari produk sebagai default
        promoPriceController: TextEditingController(),
        notesController: TextEditingController(),
      ));
      _searchResults = [];
      _searchController.clear();
    });
  }
  
  // Validasi data sebelum kirim
  bool _validateData() {
    if (_currentOutlet == null) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data toko belum termuat. Tidak bisa validasi.')));
       return false;
    }
    if (_priceItems.isEmpty) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada produk yang dipilih untuk validasi.')));
       return false;
    }

    for (int i = 0; i < _priceItems.length; i++) {
      final item = _priceItems[i];
      // Validasi Harga Normal
      if (item.normalPriceController.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Harga Normal untuk ${item.product.nama}')),
        );
        return false;
      }
       if (int.tryParse(item.normalPriceController.text) == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format Harga Normal untuk ${item.product.nama} tidak valid (harus angka bulat).')));
          return false;
       }
       if ((int.tryParse(item.normalPriceController.text) ?? 0) <= 0) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Harga Normal untuk ${item.product.nama} harus lebih dari 0.')));
           return false;
       }

      // Validasi Harga Promo (jika diisi)
       if (item.promoPriceController.text.isNotEmpty) {
          if (int.tryParse(item.promoPriceController.text) == null) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format Harga Promo untuk ${item.product.nama} tidak valid (harus angka bulat).')));
             return false;
          }
           if ((int.tryParse(item.promoPriceController.text) ?? 0) <= 0) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Harga Promo untuk ${item.product.nama} harus lebih dari 0 jika diisi.')));
             return false;
          }
       }
    }
    return true;
  }
  
  // Menyiapkan data untuk disimpan ke DB Lokal atau dikirim ke API
  Future<List<PriceMonitoringEntryModel>> _prepareDataForSync() async {
    List<PriceMonitoringEntryModel> entries = [];
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final user = await SessionManager().getCurrentUser();
    // _currentOutlet sudah di-load di initState

    if (user == null || _currentOutlet == null) {
      _logger.e(_tag, "User or Outlet data is null. Cannot prepare data for sync.");
      // Pesan error sudah ditampilkan di _validateData atau _loadOutletData
      return []; // Kembalikan list kosong jika data penting tidak ada
    }

    final String userId = user.idLogin ?? '';
    final String idPrinciple = user.idpriciple ?? '';
    final String outletId = _currentOutlet!.idOutlet ?? '';
    final String outletName = _currentOutlet!.nama ?? 'Outlet Tidak Diketahui';

    for (var item in _priceItems) {
      final String normalPrice = item.normalPriceController.text.trim();
      final String promoPrice = item.promoPriceController.text.trim();
      
      entries.add(PriceMonitoringEntryModel(
        idPrinciple: idPrinciple,
        idOutlet: outletId,
        outletName: outletName,
        idProduct: item.product.idProduk,
        productName: item.product.nama,
        hargaNormal: normalPrice,
        hargaDiskon: promoPrice.isNotEmpty ? promoPrice : null, // Kirim null jika kosong
        hargaGabungan: promoPrice.isNotEmpty ? promoPrice : normalPrice, // Asumsi harga_gabungan = harga_diskon jika ada, else harga_normal
        ket: item.notesController.text.trim(),
        sender: userId,
        tgl: currentDate,
      ));
    }
    _logger.d(_tag, "Prepared data for sync: ${entries.length} items");
    return entries;
  }

  // Dialog konfirmasi pengiriman data
  void _showSendDialog() {
     if (!_validateData()) {
       // Validasi gagal, pesan sudah ditampilkan di _validateData
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
              _sendOffline();
            }, child: const Text('Offline (Local)'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOnline();
            },
             style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Menggunakan AppColors.primary
              ),
              child: const Text('Online (Server)', style: TextStyle(color: Colors.white)),
            ),
          
        ],
      ),
    );
  }
  
  // Kirim data offline
  Future<void> _sendOffline() async {
    // Validasi sudah dilakukan di _showSendDialog
    
    setState(() {
      _isLoading = true;
    });
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    
    try {
      final List<PriceMonitoringEntryModel> entriesToSave = await _prepareDataForSync();
       if (entriesToSave.isEmpty && _priceItems.isNotEmpty) { // Ada produk dipilih tapi gagal siapkan data
         if (mounted) Navigator.pop(context); // Tutup loading
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyiapkan data untuk disimpan lokal.')));
         setState(() { _isLoading = false; });
         return;
      }
       if (entriesToSave.isEmpty && _priceItems.isEmpty) { // Tidak ada produk dipilih
         if (mounted) Navigator.pop(context); // Tutup loading
         setState(() { _isLoading = false; });
         return;
      }
      
      bool success = await _apiService.savePriceMonitoringOffline(entriesToSave);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan secara lokal'), backgroundColor: Colors.green,),
            
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan data secara lokal'), backgroundColor: Colors.red,),
            
          );
        }
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      _logger.e(_tag, "Error saving offline: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Kirim data online
  Future<void> _sendOnline() async {
    // Validasi sudah dilakukan di _showSendDialog
    
    setState(() {
      _isLoading = true;
    });
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
        );
      }
      return;
    }
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    
    try {
      final List<PriceMonitoringEntryModel> entriesToSubmit = await _prepareDataForSync();
       if (entriesToSubmit.isEmpty && _priceItems.isNotEmpty) { // Ada produk dipilih tapi gagal siapkan data
         if (mounted) Navigator.pop(context); // Tutup loading
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyiapkan data untuk dikirim ke server.')));
         setState(() { _isLoading = false; });
         return;
      }
       if (entriesToSubmit.isEmpty && _priceItems.isEmpty) { // Tidak ada produk dipilih
         if (mounted) Navigator.pop(context); // Tutup loading
         setState(() { _isLoading = false; });
         return;
      }
      
      bool success = await _apiService.submitPriceMonitoringOnline(entriesToSubmit);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dikirim ke server'), backgroundColor: Colors.green,),
            
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim data ke server'), backgroundColor: Colors.red,),
            
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      _logger.e(_tag, "Error sending online: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // Menghapus produk dari list
  void _removeProduct(int index) {
    setState(() {
      // Dispose controllers sebelum remove item
      _priceItems[index].normalPriceController.dispose();
      _priceItems[index].promoPriceController.dispose();
      _priceItems[index].notesController.dispose();
      
      _priceItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.grey[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchBarWidget(
                    controller: _searchController,
                    hintText: "Search here",
                    onChanged: (value) {
                      _searchProducts(value);
                    },
                    onScanPressed: () {
                      // Handle barcode scanning if needed
                    },
                  ),
                ),
                
                // Search results
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          title: Text(product?.nama ?? ''),
                          subtitle: Text('Code: ${product.kode ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.success),
                            onPressed: () => _addProduct(product),
                          ),
                        );
                      },
                    ),
                  )
                else if (_searchController.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Tidak ada produk ditemukan')),
                  ),
                
                // List of products with price forms
                Expanded(
                  child: _priceItems.isEmpty
                      ? const Center(child: Text('Silakan cari produk untuk memantau harga'))
                      : ListView.builder(
                          itemCount: _priceItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return _buildPriceItemCard(_priceItems[index], index); // Pass index
                          },
                        ),
                ),
              ],
            ),
      
      // Floating action button sebagai alternatif untuk pengiriman data
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Validasi dilakukan di dalam _showSendDialog
          _showSendDialog();
        },
        backgroundColor: _priceItems.isEmpty ? Colors.grey : AppColors.primary, // Disable if no items
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
  
  Widget _buildPriceItemCard(PriceItem item, int index) { // Receive index
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header with icon and delete button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.product.gambar != null
                        ? Image.network(
                            item.product.gambar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.image_not_supported), // Use Icon instead of Image.asset
                          )
                        : const Icon(Icons.inventory), // Placeholder icon
                  ),
                ),
                const SizedBox(width: 16),
                
                // Product name and barcode icon + Delete button
                Expanded(
                  child: Column( // Use Column to stack name/barcode and delete button
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( // Row for name and barcode
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded( // Use Expanded to prevent overflow
                            child: Text(
                              item.product.nama ?? 'Unknown Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis, // Handle long names
                            ),
                          ),
                          Icon(Icons.qr_code_scanner, color: Colors.grey[500]),
                        ],
                      ),
                      const SizedBox(height: 4), // Space between name/barcode and delete
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeProduct(index), // Call remove function
                          padding: EdgeInsets.zero, // Remove default padding
                          constraints: const BoxConstraints(), // Remove default constraints
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price inputs row
            Row(
              children: [
                // Harga Normal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Harga Normal'),
                      TextField(
                        controller: item.normalPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya angka bulat
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Harga Promo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Harga Promo'),
                      TextField(
                        controller: item.promoPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya angka bulat
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notes field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes:'),
                TextField(
                  controller: item.notesController,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 3, // Allow multiple lines for notes
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Class untuk menyimpan data produk dan form input
class PriceItem {
  final ProductModel product;
  final TextEditingController normalPriceController;
  final TextEditingController promoPriceController;
  final TextEditingController notesController;
  
  PriceItem({
    required this.product,
    required this.normalPriceController,
    required this.promoPriceController,
    required this.notesController,
  });
}

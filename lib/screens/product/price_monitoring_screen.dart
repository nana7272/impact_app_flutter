import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/price_monitoring_api_service.dart';
import '../../themes/app_colors.dart';
import '../../utils/connectivity_utils.dart';
import '../../models/product_model.dart';
import '../../widget/search_bar_widget.dart';

class PriceMonitoringScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const PriceMonitoringScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<PriceMonitoringScreen> createState() => _PriceMonitoringScreenState();
}

class _PriceMonitoringScreenState extends State<PriceMonitoringScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PriceMonitoringApiService _apiService = PriceMonitoringApiService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<Product> _searchResults = [];
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
      final products = await _apiService.searchProducts(keyword);
      setState(() {
        _searchResults = products;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencari produk: $e')),
      );
    }
  }
  
  // Menambahkan produk ke list
  void _addProduct(Product product) {
    // Periksa apakah produk sudah ada di list
    final existingIndex = _priceItems.indexWhere((p) => p.product.id == product.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }
    
    // Tambahkan product dengan controller baru
    setState(() {
      _priceItems.add(PriceItem(
        product: product,
        normalPriceController: TextEditingController(text: product.price?.toInt().toString() ?? ''),
        promoPriceController: TextEditingController(),
        notesController: TextEditingController(text: 'Promo sampai akhir bulan'),
      ));
      _searchResults = [];
      _searchController.clear();
    });
  }
  
  // Validasi data sebelum kirim
  bool _validateData() {
    for (int i = 0; i < _priceItems.length; i++) {
      if (_priceItems[i].normalPriceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Harga Normal untuk ${_priceItems[i].product.name}')),
        );
        return false;
      }
    }
    return true;
  }
  
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
              _sendOffline();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('Offline (Local)'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOnline();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('Online (Server)', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
  
  // Kirim data offline
  Future<void> _sendOffline() async {
    if (!_validateData()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Persiapkan data
      List<Map<String, dynamic>> priceData = [];
      
      for (var item in _priceItems) {
        priceData.add({
          'product_id': item.product.id,
          'product_name': item.product.name,
          'normal_price': item.normalPriceController.text,
          'promo_price': item.promoPriceController.text.isNotEmpty 
              ? item.promoPriceController.text 
              : null,
          'notes': item.notesController.text,
        });
      }
      
      // Simulasi penyimpanan offline
      await Future.delayed(const Duration(seconds: 1));
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
      );
      
      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Kirim data online
  Future<void> _sendOnline() async {
    if (!_validateData()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
      });
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
      // Persiapkan data
      List<Map<String, dynamic>> priceData = [];
      
      for (var item in _priceItems) {
        priceData.add({
          'product_id': item.product.id,
          'product_name': item.product.name,
          'normal_price': item.normalPriceController.text,
          'promo_price': item.promoPriceController.text.isNotEmpty 
              ? item.promoPriceController.text 
              : null,
          'notes': item.notesController.text,
        });
      }
      
      // Kirim data ke server (simulasi)
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dikirim ke server')),
      );
      
      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    
    setState(() {
      _isLoading = false;
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
                          title: Text(product.name ?? ''),
                          subtitle: Text('Code: ${product.code ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
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
                            return _buildPriceItemCard(_priceItems[index]);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Image.asset('assets/clipboard_icon.png', width: 24, height: 24),
              onPressed: () {
                // Handle clipboard action
              },
            ),
            IconButton(
              icon: Image.asset('assets/send_icon.png', width: 24, height: 24),
              onPressed: () {
                if (_priceItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tidak ada produk yang dipilih')),
                  );
                  return;
                }
                
                _showSendDialog();
              },
            ),
          ],
        ),
      ),
      // Floating action button sebagai alternatif untuk pengiriman data
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_priceItems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada produk yang dipilih')),
            );
            return;
          }
          
          _showSendDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
  
  Widget _buildPriceItemCard(PriceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header with icon
            Row(
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
                    child: item.product.image != null
                        ? Image.network(
                            item.product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Image.asset('assets/product_placeholder.png'),
                          )
                        : Image.asset('assets/product_placeholder.png'),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Product name and barcode icon
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.product.name ?? 'Unknown Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.qr_code_scanner, color: Colors.grey[500]),
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          // Auto-calculate promo price if needed
                        },
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
  final Product product;
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
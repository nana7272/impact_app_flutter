import 'package:flutter/material.dart';
import '../../api/sales_api_service.dart';
import '../../themes/app_colors.dart';
import '../../utils/connectivity_utils.dart';
import '../../models/product_sales_model.dart';
import '../../widget/search_bar_widget.dart';

class OutOfStockScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const OutOfStockScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
  final SalesApiService _apiService = SalesApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<OOSProduct> _selectedProducts = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductSales> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    for (var product in _selectedProducts) {
      product.quantityController.dispose();
      product.noteController.dispose();
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
  void _addProduct(ProductSales product) {
    // Periksa apakah produk sudah ada di list
    final existingIndex = _selectedProducts.indexWhere((p) => p.product.id == product.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }

    // Tambahkan product dengan controller baru
    setState(() {
      _selectedProducts.add(OOSProduct(
        product: product,
        quantityController: TextEditingController(),
        noteController: TextEditingController(),
        isEmpty: true,
      ));
      _searchResults = [];
      _searchController.clear();
    });
  }

  // Validasi data sebelum kirim
  bool _validateData() {
    for (int i = 0; i < _selectedProducts.length; i++) {
      if (_selectedProducts[i].quantityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Quantity untuk ${_selectedProducts[i].product.name}')),
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

  // Kirim data secara offline
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
      // Persiapkan data untuk disimpan secara lokal
      List<Map<String, dynamic>> productsData = [];
      
      for (var item in _selectedProducts) {
        productsData.add({
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantityController.text,
          'note': item.noteController.text,
          'is_empty': item.isEmpty,
        });
      }

      // Simulasi penyimpanan data lokal
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

  // Kirim data secara online
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
      // Persiapkan data untuk dikirim ke server
      List<Map<String, dynamic>> productsData = [];
      
      for (var item in _selectedProducts) {
        productsData.add({
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantityController.text,
          'note': item.noteController.text,
          'is_empty': item.isEmpty ? 1 : 0,
        });
      }

      // Simulasi pengiriman data ke server
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
        title: const Text('Out of Stock'),
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          title: Text(product.name ?? ''),
                          subtitle: Text('Code: ${product.code ?? ''} | Price: ${product.price ?? 0}'),
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
                  )
                else
                  // Selected products list
                  Expanded(
                    child: _selectedProducts.isEmpty
                        ? const Center(child: Text('Silakan cari produk untuk menambahkannya ke daftar OOS'))
                        : ListView.builder(
                            itemCount: _selectedProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(_selectedProducts[index]);
                            },
                          ),
                  ),
              ],
            ),
      // Floating action button sebagai alternatif untuk pengiriman data
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedProducts.isEmpty) {
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

  Widget _buildProductCard(OOSProduct oosProduct) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Produk name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              oosProduct.product.name?.toUpperCase() ?? 'UNKNOWN PRODUCT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Form fields container
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity field dengan toggle kosong/tersedia
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity'),
                          TextField(
                            controller: oosProduct.quantityController,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan jumlah',
                              border: UnderlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !oosProduct.isEmpty, // Disable jika kosong
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle switch kosong/tersedia
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: oosProduct.isEmpty ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            oosProduct.isEmpty ? 'Kosong' : 'Tersedia',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Switch(
                            value: !oosProduct.isEmpty,
                            onChanged: (value) {
                              setState(() {
                                oosProduct.isEmpty = !value;
                                // Kosongkan field quantity jika status kosong
                                if (oosProduct.isEmpty) {
                                  oosProduct.quantityController.text = '';
                                }
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Keterangan field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keterangan'),
                    TextField(
                      controller: oosProduct.noteController,
                      decoration: const InputDecoration(
                        hintText: 'Tambahkan keterangan',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model untuk menyimpan produk OOS beserta controller-nya
class OOSProduct {
  final ProductSales product;
  final TextEditingController quantityController;
  final TextEditingController noteController;
  bool isEmpty;
  
  OOSProduct({
    required this.product,
    required this.quantityController,
    required this.noteController,
    this.isEmpty = true,
  });
}
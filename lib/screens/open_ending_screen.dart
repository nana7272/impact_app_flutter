import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/sales_api_service.dart';
import '../themes/app_colors.dart';
import '../utils/connectivity_utils.dart';
import '../models/product_sales_model.dart';
import '../widget/search_bar_widget.dart';

class OpenEndingScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const OpenEndingScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<OpenEndingScreen> createState() => _OpenEndingScreenState();
}

class _OpenEndingScreenState extends State<OpenEndingScreen> {
  final SalesApiService _apiService = SalesApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<ProductSales> _selectedProducts = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductSales> _searchResults = [];

  // Controllers untuk setiap produk
  final Map<String, TextEditingController> _openControllers = {};
  final Map<String, TextEditingController> _inControllers = {};
  final Map<String, TextEditingController> _endingControllers = {};
  final Map<String, TextEditingController> _sellOutControllers = {};
  final Map<String, bool> _stockReturnValues = {};
  final Map<String, bool> _stockExpiredValues = {};

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose semua controllers
    for (var controller in _openControllers.values) {
      controller.dispose();
    }
    for (var controller in _inControllers.values) {
      controller.dispose();
    }
    for (var controller in _endingControllers.values) {
      controller.dispose();
    }
    for (var controller in _sellOutControllers.values) {
      controller.dispose();
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
    final existingIndex = _selectedProducts.indexWhere((p) => p.id == product.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }

    setState(() {
      _selectedProducts.add(product);
      _searchResults = [];
      _searchController.clear();
      
      // Inisialisasi controllers untuk produk baru
      _openControllers[product.id!] = TextEditingController();
      _inControllers[product.id!] = TextEditingController();
      _endingControllers[product.id!] = TextEditingController();
      _sellOutControllers[product.id!] = TextEditingController();
      _stockReturnValues[product.id!] = false;
      _stockExpiredValues[product.id!] = false;
    });
  }

  // Menghapus produk dari list
  void _removeProduct(int index) {
    final productId = _selectedProducts[index].id!;
    
    setState(() {
      // Hapus controllers
      _openControllers[productId]?.dispose();
      _inControllers[productId]?.dispose();
      _endingControllers[productId]?.dispose();
      _sellOutControllers[productId]?.dispose();
      
      _openControllers.remove(productId);
      _inControllers.remove(productId);
      _endingControllers.remove(productId);
      _sellOutControllers.remove(productId);
      _stockReturnValues.remove(productId);
      _stockExpiredValues.remove(productId);
      
      _selectedProducts.removeAt(index);
    });
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
            child: const Text('Offline (Local)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOnline();
            },
            child: const Text('Online (Server)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Kirim data offline
  Future<void> _sendOffline() async {
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
      // Implementasi penyimpanan data offline di sini
      
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
      );
      Navigator.pop(context); // Kembali ke layar sebelumnya
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
      // Implementasi pengiriman data ke server di sini
      
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dikirim ke server')),
      );
      Navigator.pop(context); // Kembali ke layar sebelumnya
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

  // Validasi data sebelum kirim
  bool _validateData() {
    for (var product in _selectedProducts) {
      final productId = product.id!;
      if (_openControllers[productId]?.text.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Open untuk ${product.name}')),
        );
        return false;
      }
      if (_inControllers[productId]?.text.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi In untuk ${product.name}')),
        );
        return false;
      }
      if (_endingControllers[productId]?.text.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Ending untuk ${product.name}')),
        );
        return false;
      }
      if (_sellOutControllers[productId]?.text.isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Sell Out untuk ${product.name}')),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Ending'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.grey[700],
      ),
      body: Column(
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
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    leading: product.image != null
                        ? Image.network(
                            product.image!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.inventory),
                    title: Text(product.name ?? ''),
                    subtitle: Text('Stok: ${product.stock} | Harga: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(product.price)}'),
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
            )
          else
            const SizedBox(),
          
          // Selected products
          Expanded(
            child: _selectedProducts.isEmpty
                ? const Center(child: Text('Tambahkan produk dengan mencari di kolom pencarian.'))
                : ListView.builder(
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      final productId = product.id!;
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name?.toUpperCase() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    // Row 1: Open, In, Ending
                                    Row(
                                      children: [
                                        _buildInputField('Open', _openControllers[productId]!, width: (MediaQuery.of(context).size.width - 80) / 3),
                                        _buildInputField('In', _inControllers[productId]!, width: (MediaQuery.of(context).size.width - 80) / 3),
                                        _buildInputField('Ending', _endingControllers[productId]!, width: (MediaQuery.of(context).size.width - 80) / 3),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Row 2: Sell out
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Sell out', style: TextStyle(color: Colors.grey[700])),
                                    ),
                                    TextField(
                                      controller: _sellOutControllers[productId],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Row 3: Checkboxes
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity: ListTileControlAffinity.leading,
                                            title: const Text("Stock Return"),
                                            value: _stockReturnValues[productId] ?? false,
                                            onChanged: (value) {
                                              setState(() {
                                                _stockReturnValues[productId] = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        Container(
                                          width: 60,
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity: ListTileControlAffinity.leading,
                                            title: const Text("Stock Expired"),
                                            value: _stockExpiredValues[productId] ?? false,
                                            onChanged: (value) {
                                              setState(() {
                                                _stockExpiredValues[productId] = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        Container(
                                          width: 60,
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedProducts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada produk yang dipilih')),
            );
            return;
          }
          
          if (_validateData()) {
            _showSendDialog();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.send, color: Colors.white),
      ),
      
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
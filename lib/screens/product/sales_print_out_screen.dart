import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/offline/ofline_data_manager.dart';
import 'package:impact_app/widget/search_bar_widget.dart';
import 'package:intl/intl.dart';
import '../../api/sales_api_service.dart';
import '../../database/database_helper.dart';
import '../../models/product_sales_model.dart';
import '../../themes/app_colors.dart';
import '../../utils/connectivity_utils.dart';
import '../../utils/logger.dart';
import '../../utils/session_manager.dart';

// Custom Badge widget untuk platform compatibility
class Badge extends StatelessWidget {
  final Widget child;
  final Widget? label;
  final Color? backgroundColor;
  
  const Badge({
    Key? key,
    required this.child,
    this.label,
    this.backgroundColor = Colors.red,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        child,
        if (label != null)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                child: label!,
              ),
            ),
          ),
      ],
    );
  }
}

class SalesPrintOutScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const SalesPrintOutScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<SalesPrintOutScreen> createState() => _SalesPrintOutScreenState();
}

class _SalesPrintOutScreenState extends State<SalesPrintOutScreen> {
  final SalesApiService _apiService = SalesApiService();
  //final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();
  final String _tag = 'SalesPrintOutScreen';
  final TextEditingController _searchController = TextEditingController();
  final List<ProductSales> _selectedProducts = [];
  final List<File?> _productPhotos = [];
  final OfflineDataManager _offlineDataManager = OfflineDataManager();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductSales> _searchResults = [];
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingData();
    _logger.d(_tag, 'Initialized with storeId: ${widget.storeId}, visitId: ${widget.visitId}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check for pending offline data
  Future<void> _checkPendingData() async {
    try {
      //final count = await _dbHelper.getPendingCount();
      setState(() {
        //_pendingCount = count;
      });
      _logger.d(_tag, 'Pending offline data count: $_pendingCount');
    } catch (e) {
      _logger.e(_tag, 'Error checking pending data: $e');
    }
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
      _logger.d(_tag, 'Found ${products.length} products for keyword: $keyword');
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _logger.e(_tag, 'Error searching products: $e');
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
      _productPhotos.add(null);
      _searchResults = [];
      _searchController.clear();
    });
    
    _logger.d(_tag, 'Added product: ${product.name}');
  }

  // Menghapus produk dari list
  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
      _productPhotos.removeAt(index);
    });
    
    _logger.d(_tag, 'Removed product at index: $index');
  }

  // Mengambil foto produk
  Future<void> _takePicture(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _productPhotos[index] = File(image.path);
      });
      _logger.d(_tag, 'Took picture for product at index: $index');
    }
  }

  // Validasi data form
  bool _validateForm() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tambahkan minimal 1 produk')),
      );
      return false;
    }

    for (int i = 0; i < _selectedProducts.length; i++) {
      if (_selectedProducts[i].sellOutQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity untuk produk ${_selectedProducts[i].name} harus diisi')),
        );
        return false;
      }
      
      if (_selectedProducts[i].sellOutValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Value untuk produk ${_selectedProducts[i].name} harus diisi')),
        );
        return false;
      }
      
      if (_selectedProducts[i].periode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Periode untuk produk ${_selectedProducts[i].name} harus diisi')),
        );
        return false;
      }
    }

    return true;
  }

  // Menyimpan form data sales print out
  void _saveForm() {
    // Validasi data
    if (!_validateForm()) {
      return;
    }

    // Tampilkan dialog konfirmasi
    _showSendDialog();
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
      List<String?> photosPaths = [];
      for (var photo in _productPhotos) {
        photosPaths.add(photo?.path);
      }

      bool success = await _apiService.saveSalesPrintOutOffline(
        widget.storeId,
        widget.visitId,
        _selectedProducts,
        photosPaths,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
          );
          Navigator.pop(context); // Kembali ke layar sebelumnya
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
          );
        }
      }
      
      // Update pending count
      await _checkPendingData();
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      _logger.e(_tag, 'Error saving offline: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Future<void> _sendOffline() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   // Show loading dialog
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const Center(child: CircularProgressIndicator()),
  //   );

  //   try {
  //     List<String?> photosPaths = [];
  //       for (var photo in _productPhotos) {
  //         photosPaths.add(photo?.path);
  //       }

  //       // Create the data to save
  //       final Map<String, dynamic> data = {
  //         'store_id': widget.storeId,
  //         'visit_id': widget.visitId,
  //         'user_id': (await SessionManager().getCurrentUser())?.id, // Get user ID
  //         'created_at': DateTime.now().toIso8601String(),
  //         'status': 'pending',
  //         'items': _selectedProducts.map((p) => {
  //           'product_id': p.id,
  //           'product_name': p.name,
  //           'sell_out_qty': p.sellOutQty,
  //           'sell_out_value': p.sellOutValue,
  //           'periode': p.periode,
  //           'photo_path': photosPaths[_selectedProducts.indexOf(p)],
  //         }).toList(),
  //       };

  //     bool success = await _offlineDataManager.saveDataOffline('sales_print_outs', data); // Use the offline data manager

  //     // Close loading dialog
  //     if (context.mounted) Navigator.pop(context);

  //     if (success) {
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
  //         );
  //         Navigator.pop(context); // Kembali ke layar sebelumnya
  //       }
  //     } else {
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     // Close loading dialog
  //     if (context.mounted) Navigator.pop(context);
      
  //     _logger.e(_tag, 'Error saving offline: $e');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error: $e')),
  //       );
  //     }
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
        );
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Get user information to make sure it's included in the request
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null) {
        _logger.e(_tag, 'User data not found');
        
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data user tidak ditemukan')),
          );
        }
        
        setState(() => _isLoading = false);
        return;
      }
      
      // Log user info for debugging
      _logger.d(_tag, 'Sending with user_id: ${user.idLogin}');
      
      bool success = await _apiService.submitSalesPrintOut(
        widget.storeId,
        widget.visitId,
        _selectedProducts,
        _productPhotos,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dikirim ke server')),
          );
          Navigator.pop(context); // Kembali ke layar sebelumnya
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim data ke server')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      _logger.e(_tag, 'Error sending online: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Sync pending data
  Future<void> _syncPendingData() async {
    if (_pendingCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data pending untuk disinkronkan')),
      );
      return;
    }

    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada koneksi internet untuk sinkronisasi')),
      );
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
      bool success = await _apiService.syncOfflineSalesPrintOut();
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinkronisasi data berhasil')),
        );
        
        // Update pending count
        await _checkPendingData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal sinkronisasi data')),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      _logger.e(_tag, 'Error syncing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sinkronisasi: $e')),
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
        title: const Text('Sales Print Out'),
        backgroundColor: AppColors.secondary,
        actions: [
          if (_pendingCount > 0)
            IconButton(
              icon: Badge(
                label: Text('$_pendingCount'),
                child: const Icon(Icons.sync),
              ),
              onPressed: _syncPendingData,
              tooltip: 'Sync pending data',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: "Cari produk...",
              onScanPressed: () {
                // Handle barcode scanning if needed
              },
              onChanged: (value) {
                _searchProducts(value);
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
                ? const Center(child: Text('Belum ada produk yang dipilih'))
                : ListView.builder(
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product header with delete button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () => _removeProduct(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Photo section
                              GestureDetector(
                                onTap: () => _takePicture(index),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _productPhotos[index] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _productPhotos[index]!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('Click to add photo'),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Form fields
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Sell out in qty'),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (value) {
                                            if (value.isNotEmpty) {
                                              setState(() {
                                                product.sellOutQty = int.parse(value);
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Sell out in value'),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (value) {
                                            if (value.isNotEmpty) {
                                              setState(() {
                                                product.sellOutValue = double.parse(value);
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Periode'),
                              TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  hintText: 'Januari 2025',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    product.periode = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Save button
          if (_selectedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SIMPAN DATA', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
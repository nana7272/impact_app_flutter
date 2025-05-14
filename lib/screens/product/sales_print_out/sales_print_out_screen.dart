import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/offline/ofline_data_manager.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/widget/search_bar_widget.dart';
import 'package:intl/intl.dart';
import 'api/sales_printout_api_service.dart';
import '../../../database/database_helper.dart';
import '../../../models/product_sales_model.dart';
import '../../../themes/app_colors.dart';
import '../../../utils/connectivity_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/session_manager.dart';

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
  final SalesByPrintOutApiService _apiService = SalesByPrintOutApiService();
  final Logger _logger = Logger();
  final String _tag = 'SalesPrintOutScreen';
  final TextEditingController _searchController = TextEditingController();
  final List<ProductSales> _selectedProducts = [];
  final List<File?> _productPhotos = [];
  final List<TextEditingController> _periodeControllers = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _logger.d(_tag, 'Initialized with storeId: ${widget.storeId}, visitId: ${widget.visitId}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _periodeControllers) {
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
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword);

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
  void _addProduct(ProductModel product) {
    // Periksa apakah produk sudah ada di list
    final existingIndex = _selectedProducts.indexWhere((p) => p.id == product.idProduk);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }

    setState(() {
      final newProductSales = ProductSales(
        id: product.idProduk,
        name: product.nama,
        stock: 0,
        price: double.tryParse(product.harga ?? '0'),
        image: product.gambar,
        sellOutQty: 0,
        sellOutValue: 0,
        periode: '', // Periode diinisialisasi kosong
      );
      _selectedProducts.add(newProductSales);
      _productPhotos.add(null);
      // Tambahkan controller untuk field periode produk baru
      _periodeControllers.add(TextEditingController(text: newProductSales.periode));
      _searchResults = [];
      _searchController.clear();
    });
    _logger.d(_tag, 'Added product: ${product.nama}');
  }

  // Menghapus produk dari list
  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
      _productPhotos.removeAt(index);
      // Hapus dan dispose controller yang sesuai
      _periodeControllers[index].dispose();
      _periodeControllers.removeAt(index);
    });
    _logger.d(_tag, 'Removed product at index: $index');
  }

  // Mengambil foto produk
  Future<void> _takePicture(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 30);
    
    if (image != null) {
      setState(() {
        _productPhotos[index] = File(image.path);
      });
      _logger.d(_tag, 'Took picture for product at index: $index');
    }
  }

  // Method untuk memilih rentang tanggal periode
  Future<void> _pickPeriod(BuildContext context, int index) async {
    final product = _selectedProducts[index];
    final controller = _periodeControllers[index];

    DateTimeRange? initialRange;
    // Coba parse periode yang sudah ada untuk initialDateRange
    if (product.periode.isNotEmpty) {
      try {
        final parts = product.periode.split(' - ');
        if (parts.length == 2) {
          final DateFormat formatter = DateFormat('dd/MM/yyyy');
          final DateTime startDate = formatter.parse(parts[0]);
          final DateTime endDate = formatter.parse(parts[1]);
          initialRange = DateTimeRange(start: startDate, end: endDate);
        }
      } catch (e) {
        _logger.w(_tag, "Gagal mem-parse string periode: ${product.periode}, error: $e");
      }
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5), // Batas awal 5 tahun lalu
      lastDate: DateTime(DateTime.now().year + 5),  // Batas akhir 5 tahun ke depan
      initialDateRange: initialRange,
      helpText: 'Pilih Rentang Periode',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      errorFormatText: 'Format tanggal salah',
      errorInvalidText: 'Tanggal tidak valid',
      errorInvalidRangeText: 'Rentang tidak valid',
      fieldStartHintText: 'Tanggal Mulai',
      fieldEndHintText: 'Tanggal Selesai',
    );

    if (picked != null) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final formattedDateRange = '${formatter.format(picked.start)} - ${formatter.format(picked.end)}';
      setState(() {
        product.periode = formattedDateRange;
        controller.text = formattedDateRange;
      });
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Print Out'),
        backgroundColor: AppColors.secondary,
        
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
                    leading: product.gambar != null
                        ? Image.network(
                            product.gambar!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.inventory),
                    title: Text(product.nama),
                    subtitle: Text('Kode: ${product.kode}'),
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
                              TextFormField(
                                controller: _periodeControllers[index],
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  hintText: 'Pilih Periode',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () {
                                  _pickPeriod(context, index);
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
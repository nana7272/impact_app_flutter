import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'dart:io';
import '../../../utils/connectivity_utils.dart';
import '../../../utils/logger.dart';
import '../../../utils/session_manager.dart';
import 'api/availability_api_service.dart';
import '../../../widget/search_bar_widget.dart';

class AvailabilityScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const AvailabilityScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AvailabilityApiService _apiService = AvailabilityApiService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];
  List<ProductAvailability> _productAvailabilityList = [];
  File? _beforeImage;
  File? _afterImage;
  Store? _currentStore;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      _currentStore = await SessionManager().getStoreData();
      if (_currentStore == null || _currentStore!.idOutlet != widget.storeId) {
        // Jika storeId dari argumen berbeda dengan session, mungkin perlu logika tambahan
        _logger.w("AvailabilityScreen", "Store ID from argument (${widget.storeId}) might differ from session store.");
      }
      if(mounted) setState(() {});
    } catch (e) {
      _logger.e("AvailabilityScreen", "Error loading store data: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data toko.")));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search for products
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
      // This would be connected to your actual API
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword);
      
      // Filter products based on keyword (simulate search)
      final filteredProducts = products.where((product) => 
        product.nama?.toLowerCase().contains(keyword.toLowerCase()) ?? false).toList();
      
      setState(() {
        _searchResults = filteredProducts;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: $e')),
      );
    }
  }

  // Add product to the availability list
  void _addProduct(ProductModel product) {
    // Check if product already exists in the list
    final existingIndex = _productAvailabilityList.indexWhere((p) => p.product.idProduk == product.idProduk);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product already added')),
      );
      return;
    }

    setState(() {
      _productAvailabilityList.add(
        ProductAvailability(
          product: product,
          stockGudang: 0,
          stockDisplay: 0,
          totalStock: 0,
          status: ProductStatus.neutral,
        ),
      );
      _searchResults = [];
      _searchController.clear();
    });
  
  }

  // Update stock values and calculate totals
  void _updateStockGudang(int index, int value) {
    setState(() {
      _productAvailabilityList[index].stockGudang = value;
      _updateTotalStock(index);
    });
  
  }

  void _updateStockDisplay(int index, int value) {
    setState(() {
      _productAvailabilityList[index].stockDisplay = value;
      _updateTotalStock(index);
    });
  }

  void _updateTotalStock(int index) {
    int total = _productAvailabilityList[index].stockGudang + 
                _productAvailabilityList[index].stockDisplay;
    
    setState(() {
      _productAvailabilityList[index].totalStock = total;
      
      // Update status based on total stock
      if (total <= 5) {
        _productAvailabilityList[index].status = ProductStatus.critical;
      } else if (total <= 10) {
        _productAvailabilityList[index].status = ProductStatus.warning;
      } else {
        _productAvailabilityList[index].status = ProductStatus.good;
      }
    });
  }

  // Take before/after images
  Future<void> _takeImage(bool isBeforeImage) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (image != null) {
      setState(() {
        if (isBeforeImage) {
          _beforeImage = File(image.path);
        } else {
          _afterImage = File(image.path);
        }
      });
    }
  }

  void _clearImage(bool isBeforeImage) {
    if (mounted) {
      setState(() {
        if (isBeforeImage) {
          _beforeImage = null;
        } else {
          _afterImage = null;
        }
      });
    }
  }

  // Show send data dialog
  void _showSendDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kirim Data', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kirim data menggunakan metode?'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _sendData(false); // Offline
                    },
                    child: const Text('Offline (Local)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _sendData(true); // Online
                    },
                    child: const Text('Online (Server)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Send data based on online/offline mode
  Future<void> _sendData(bool isOnline) async {
    // Validate data
    if (_productAvailabilityList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to submit')),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_beforeImage == null || _afterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon ambil foto Before dan After.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final user = await SessionManager().getCurrentUser();
      if (user == null || user.idLogin == null) {
        throw Exception("User not logged in.");
      }
      if (_currentStore == null || _currentStore!.idOutlet == null) {
        throw Exception("Store data not available.");
      }

      List<Map<String, dynamic>> itemsPayload = _productAvailabilityList.map((pa) => {
        'id_product': pa.product.idProduk,
        'stock_gudang': pa.stockGudang,
        'stock_display': pa.stockDisplay,
        'total_stock': pa.totalStock,
      }).toList();

      if (isOnline) {
        bool isConnected = await ConnectivityUtils.checkInternetConnection();
        if (!isConnected) {
          if(mounted) Navigator.pop(context);
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection. Use offline method.')),
          );
          return;
        }
        
        bool success = await _apiService.submitAvailabilityDataOnline(
          idUser: user.idLogin!,
          idOutlet: _currentStore!.idOutlet!,
          imageBeforeFile: _beforeImage,
          imageAfterFile: _afterImage,
          items: itemsPayload,
        );

        if(mounted) Navigator.pop(context); // Close loading
        if (success) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data sent to server successfully')));
          if(mounted) Navigator.pop(context); // Go back
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send data to server.')));
        }

      } else {
        Map<String, dynamic> headerData = {
          'id_user': user.idLogin,
          'id_outlet': _currentStore!.idOutlet,
          'outlet_name': _currentStore!.nama,
          'image_before_path': _beforeImage?.path,
          'image_after_path': _afterImage?.path,
          // tgl_submission and is_synced will be handled by ApiService
        };

        List<Map<String, dynamic>> itemsToSave = _productAvailabilityList.map((pa) => {
          'id_product': pa.product.idProduk,
          'product_name': pa.product.nama,
          'stock_gudang': pa.stockGudang,
          'stock_display': pa.stockDisplay,
          'total_stock': pa.totalStock,
        }).toList();

        bool success = await _apiService.saveAvailabilityDataOffline(headerData, itemsToSave);
        
        if(mounted) Navigator.pop(context); // Close loading
        if (success) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data saved offline')));
          if(mounted) Navigator.pop(context); // Go back
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save data offline.')));
        }
      }
    } catch (e) {
      _logger.e("AvailabilityScreen", "Error sending data: $e");
      if(mounted) Navigator.pop(context); // Close loading
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Availability - ${_currentStore?.nama ?? widget.storeId}'),
        backgroundColor: Colors.grey[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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

          _buildImagePickers(),
          
          // Search results or product list
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: _productAvailabilityList.isNotEmpty
          ? FloatingActionButton(
              heroTag: "availability_fab",
              onPressed: _showSendDataDialog,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.send),
            )
          : null,
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: product.gambar != null
                ? Image.network(
                    product.gambar!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.inventory_2_outlined, size: 32),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 32),
            title: Text(product.nama ?? 'Unknown Product'),
            subtitle: Text('Code: ${product.kode}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => _addProduct(product),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    if (_productAvailabilityList.isEmpty) {
      return const Center(
        child: Text('Search for products to add'),
      );
    }

    return ListView.builder(
      itemCount: _productAvailabilityList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return _buildProductCard(index);
      },
    );
  }

  Widget _buildImagePickers() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildImagePickerItem(
            label: 'Foto Display Before',
            imageFile: _beforeImage,
            onTap: () => _takeImage(true),
            onClear: () => _clearImage(true),
          ),
          _buildImagePickerItem(
            label: 'Foto Display After',
            imageFile: _afterImage,
            onTap: () => _takeImage(false),
            onClear: () => _clearImage(false),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerItem({
    required String label,
    File? imageFile,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.width * 0.4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : const Center(child: Icon(Icons.camera_alt, size: 40, color: Colors.grey)),
          ),
        ),
        if (imageFile != null)
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 18, color: Colors.redAccent),
            label: const Text('Hapus Gambar', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(50, 20), // Adjust size to be smaller
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        else
          const SizedBox(height: 36), // Placeholder for button height to maintain layout
      ],
    );
  }



  Widget _buildProductCard(int index) {
    final product = _productAvailabilityList[index];
    
    // Status color indicator
    Color statusColor;
    switch (product.status) {
      case ProductStatus.good:
        statusColor = Colors.green;
        break;
      case ProductStatus.warning:
        statusColor = Colors.orange;
        break;
      case ProductStatus.critical:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Product row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.product.gambar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.product.gambar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 40),
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 40),
                ),
                
                const SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.product.nama ?? 'Unknown Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Stock controls
                      Row(
                        children: [
                          // Warehouse stock
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stok Gudang'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStockButton(
                                      icon: Icons.add,
                                      onPressed: () {
                                        _updateStockGudang(index, product.stockGudang + 1);
                                      },
                                    ),
                                    Container(
                                      width: 30,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${product.stockGudang}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildStockButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        if (product.stockGudang > 0) {
                                          _updateStockGudang(index, product.stockGudang - 1);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Display stock
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stok Display'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStockButton(
                                      icon: Icons.add,
                                      onPressed: () {
                                        _updateStockDisplay(index, product.stockDisplay + 1);
                                      },
                                    ),
                                    Container(
                                      width: 30,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${product.stockDisplay}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildStockButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        if (product.stockDisplay > 0) {
                                          _updateStockDisplay(index, product.stockDisplay - 1);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Total stock row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Stok'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: product.totalStock > 30 ? 1.0 : product.totalStock / 30,
                  backgroundColor: Colors.grey[300],
                  color: statusColor,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.totalStock}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
          ],
        ),
      ),
    );
  }

  Widget _buildStockButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// Models for product availability
enum ProductStatus {
  neutral,
  good,
  warning,
  critical,
}

class ProductAvailability {
  final ProductModel product;
  int stockGudang;
  int stockDisplay;
  int totalStock;
  String? beforeImagePath;
  String? afterImagePath;
  ProductStatus status;

  ProductAvailability({
    required this.product,
    this.stockGudang = 0,
    this.stockDisplay = 0,
    this.totalStock = 0,
    this.beforeImagePath,
    this.afterImagePath,
    this.status = ProductStatus.neutral,
  });
}
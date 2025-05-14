import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../api/api_services.dart';
import '../../api/api_constants.dart';
import '../../themes/app_colors.dart';
import '../../utils/connectivity_utils.dart';
import '../../widget/search_bar_widget.dart';

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
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<Product> _searchResults = [];
  List<ProductAvailability> _productAvailabilityList = [];
  File? _beforeImage;
  File? _afterImage;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load any saved local data
  Future<void> _loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('availability_${widget.storeId}_${widget.visitId}');
    
    if (savedData != null) {
      try {
        Map<String, dynamic> data = json.decode(savedData);
        List<dynamic> products = data['products'];
        
        setState(() {
          _productAvailabilityList = products.map((item) {
            Product product = Product(
              id: item['id'],
              code: item['code'],
              name: item['name'],
              price: item['price'] != null ? double.parse(item['price'].toString()) : 0,
              image: item['image'],
            );
            
            return ProductAvailability(
              product: product,
              stockGudang: item['stockGudang'] ?? 0,
              stockDisplay: item['stockDisplay'] ?? 0,
              totalStock: item['totalStock'] ?? 0,
              beforeImagePath: item['beforeImagePath'],
              afterImagePath: item['afterImagePath'],
              status: _getStatusFromValue(item['statusValue'] ?? 0),
            );
          }).toList();
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }

  // Save current data locally
  Future<void> _saveLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    List<Map<String, dynamic>> productsList = _productAvailabilityList.map((item) {
      return {
        'id': item.product.id,
        'code': item.product.code,
        'name': item.product.name,
        'price': item.product.price,
        'image': item.product.image,
        'stockGudang': item.stockGudang,
        'stockDisplay': item.stockDisplay,
        'totalStock': item.totalStock,
        'beforeImagePath': item.beforeImagePath,
        'afterImagePath': item.afterImagePath,
        'statusValue': _getStatusValue(item.status),
      };
    }).toList();
    
    Map<String, dynamic> data = {
      'storeId': widget.storeId,
      'visitId': widget.visitId,
      'products': productsList,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString('availability_${widget.storeId}_${widget.visitId}', json.encode(data));
  }

  int _getStatusValue(ProductStatus status) {
    switch (status) {
      case ProductStatus.good: return 1;
      case ProductStatus.warning: return 2;
      case ProductStatus.critical: return 3;
      default: return 0;
    }
  }

  ProductStatus _getStatusFromValue(int value) {
    switch (value) {
      case 1: return ProductStatus.good;
      case 2: return ProductStatus.warning;
      case 3: return ProductStatus.critical;
      default: return ProductStatus.neutral;
    }
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
      final products = await _apiService.getProducts();
      
      // Filter products based on keyword (simulate search)
      final filteredProducts = products.where((product) => 
        product.name?.toLowerCase().contains(keyword.toLowerCase()) ?? false).toList();
      
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
  void _addProduct(Product product) {
    // Check if product already exists in the list
    final existingIndex = _productAvailabilityList.indexWhere((p) => p.product.id == product.id);
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
    
    _saveLocalData();
  }

  // Update stock values and calculate totals
  void _updateStockGudang(int index, int value) {
    setState(() {
      _productAvailabilityList[index].stockGudang = value;
      _updateTotalStock(index);
    });
    
    _saveLocalData();
  }

  void _updateStockDisplay(int index, int value) {
    setState(() {
      _productAvailabilityList[index].stockDisplay = value;
      _updateTotalStock(index);
    });
    
    _saveLocalData();
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
  Future<void> _takeImage(int index, bool isBefore) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        if (isBefore) {
          _productAvailabilityList[index].beforeImagePath = image.path;
        } else {
          _productAvailabilityList[index].afterImagePath = image.path;
        }
      });
      
      _saveLocalData();
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
      return;
    }

    setState(() => _isLoading = true);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      if (isOnline) {
        // Check internet connection
        bool isConnected = await ConnectivityUtils.checkInternetConnection();
        
        if (!isConnected) {
          // Close loading dialog
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection. Use offline method.')),
          );
          
          setState(() => _isLoading = false);
          return;
        }
        
        // In a real implementation, you would call your API here
        // For demonstration, we'll just simulate a delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sent to server successfully')),
        );
        
        // Clear local data after successful submission
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('availability_${widget.storeId}_${widget.visitId}');
        
        // Return to previous screen
        Navigator.pop(context);
      } else {
        // Save data locally (already done incrementally)
        await Future.delayed(const Duration(seconds: 1));
        
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved offline')),
        );
        
        // Return to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
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

          // Display Before/After images at the top
          if (_productAvailabilityList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Display Before'),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _beforeImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _beforeImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Image.asset(
                                  'assets/store_placeholder.jpg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Display After'),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _afterImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _afterImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Image.asset(
                                  'assets/store_placeholder.jpg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
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
              onPressed: _showSendDataDialog,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.send),
            )
          : null,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add_chart),
              onPressed: () {},
            ),
          ],
        ),
      ),
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
            leading: product.image != null
                ? Image.network(
                    product.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.inventory_2_outlined, size: 32),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 32),
            title: Text(product.name ?? 'Unknown Product'),
            subtitle: Text('Code: ${product.code}'),
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
                  child: product.product.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.product.image!,
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
                              product.product.name ?? 'Unknown Product',
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
            
            // Before/After images
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _takeImage(index, true),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product.beforeImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(product.beforeImagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text('Display Before', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _takeImage(index, false),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product.afterImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(product.afterImagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text('Display After', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
  final Product product;
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../api/competitor_api_service.dart';
import '../themes/app_colors.dart';
import '../utils/connectivity_utils.dart';
import '../models/product_model.dart';
import '../models/competitor_model.dart';
import '../widget/search_bar_widget.dart';
import 'package:intl/intl.dart';

class CompetitorScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const CompetitorScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<CompetitorScreen> createState() => _CompetitorScreenState();
}

class _CompetitorScreenState extends State<CompetitorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CompetitorApiService _apiService = CompetitorApiService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<Product> _searchResults = [];
  List<CompetitorItem> _competitorItems = [];
  
  final List<String> _promoTypes = [
    'PROMO RAFRAKSI',
    'PROMO DISKON',
    'PROMO BUNDLING',
    'PROMO CASHBACK',
    'TANPA PROMO',
  ];
  
  final List<String> _promoMechanisms = [
    'PROMO',
    'VOUCHER',
    'POINT REWARD',
    'CASHBACK',
    'BONUS PRODUCT',
    'NONE',
  ];
  
  @override
  void dispose() {
    _searchController.dispose();
    for (var item in _competitorItems) {
      // Dispose all text controllers
      item.ownProductController.dispose();
      item.ownRbpController.dispose();
      item.ownCbpController.dispose();
      item.ownOutletController.dispose();
      item.ownPromoTypeController.dispose();
      item.ownPromoMechanismController.dispose();
      item.ownPeriodeController.dispose();
      
      item.competitorProductController.dispose();
      item.competitorNormalController.dispose();
      item.competitorCbpController.dispose();
      item.competitorOutletController.dispose();
      item.competitorPromoTypeController.dispose();
      item.competitorPromoMechanismController.dispose();
      item.competitorPeriodeController.dispose();
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
    final existingIndex = _competitorItems.indexWhere((p) => p.product.id == product.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }
    
    // Create new controllers
    final item = CompetitorItem(
      product: product,
      ownProductController: TextEditingController(text: product.name),
      ownRbpController: TextEditingController(text: product.price?.toInt().toString() ?? '10000'),
      ownCbpController: TextEditingController(text: '8000'),
      ownOutletController: TextEditingController(text: '8000'),
      ownPromoTypeController: TextEditingController(text: _promoTypes.first),
      ownPromoMechanismController: TextEditingController(text: _promoMechanisms.first),
      ownPeriodeController: TextEditingController(text: _getDefaultPeriod()),
      
      competitorProductController: TextEditingController(text: product.name),
      competitorNormalController: TextEditingController(text: product.price?.toInt().toString() ?? '10000'),
      competitorCbpController: TextEditingController(text: '8000'),
      competitorOutletController: TextEditingController(text: '8000'),
      competitorPromoTypeController: TextEditingController(text: _promoTypes.first),
      competitorPromoMechanismController: TextEditingController(text: _promoMechanisms.first),
      competitorPeriodeController: TextEditingController(text: _getDefaultPeriod()),
    );
    
    // Add to list
    setState(() {
      _competitorItems.add(item);
      _searchResults = [];
      _searchController.clear();
    });
  }
  
  // Get default period (current day to 10 days later)
  String _getDefaultPeriod() {
    final now = DateTime.now();
    final tenDaysLater = now.add(const Duration(days: 10));
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(now)} - ${formatter.format(tenDaysLater)}';
  }
  
  // Pick image 
  Future<void> _pickOwnProductImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _competitorItems[index].ownProductImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  // Pick competitor product image
  Future<void> _pickCompetitorProductImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _competitorItems[index].competitorProductImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }
  
  // Select period
  Future<void> _selectPeriod(TextEditingController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 10)),
      ),
    );
    
    if (picked != null) {
      final formatter = DateFormat('dd MMM yyyy');
      controller.text = '${formatter.format(picked.start)} - ${formatter.format(picked.end)}';
    }
  }
  
  // Validasi data sebelum kirim
  bool _validateData() {
    if (_competitorItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada produk yang ditambahkan')),
      );
      return false;
    }
    
    for (int i = 0; i < _competitorItems.length; i++) {
      final item = _competitorItems[i];
      
      if (item.ownProductController.text.isEmpty || 
          item.competitorProductController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama produk tidak boleh kosong untuk item ${i+1}')),
        );
        return false;
      }
      
      if (item.ownRbpController.text.isEmpty || 
          item.competitorNormalController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harga produk tidak boleh kosong untuk item ${i+1}')),
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
      // Prepare data
      List<Map<String, dynamic>> itemsData = [];
      List<String> ownImagePaths = [];
      List<String> competitorImagePaths = [];
      
      for (var item in _competitorItems) {
        itemsData.add({
          'product_id': item.product.id,
          'own_product_name': item.ownProductController.text,
          'own_rbp': item.ownRbpController.text,
          'own_cbp': item.ownCbpController.text,
          'own_outlet': item.ownOutletController.text,
          'own_promo_type': item.ownPromoTypeController.text,
          'own_promo_mechanism': item.ownPromoMechanismController.text,
          'own_periode': item.ownPeriodeController.text,
          
          'competitor_product_name': item.competitorProductController.text,
          'competitor_normal': item.competitorNormalController.text,
          'competitor_cbp': item.competitorCbpController.text,
          'competitor_outlet': item.competitorOutletController.text,
          'competitor_promo_type': item.competitorPromoTypeController.text,
          'competitor_promo_mechanism': item.competitorPromoMechanismController.text,
          'competitor_periode': item.competitorPeriodeController.text,
        });
        
        ownImagePaths.add(item.ownProductImage?.path ?? '');
        competitorImagePaths.add(item.competitorProductImage?.path ?? '');
      }
      
      // Save offline
      await _apiService.saveCompetitorOffline(
        widget.storeId,
        widget.visitId,
        itemsData,
        ownImagePaths,
        competitorImagePaths,
      );
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
      );
      
      // Go back to previous screen
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
      // Prepare data
      List<Map<String, dynamic>> itemsData = [];
      List<File?> ownImages = [];
      List<File?> competitorImages = [];
      
      for (var item in _competitorItems) {
        itemsData.add({
          'product_id': item.product.id,
          'own_product_name': item.ownProductController.text,
          'own_rbp': item.ownRbpController.text,
          'own_cbp': item.ownCbpController.text,
          'own_outlet': item.ownOutletController.text,
          'own_promo_type': item.ownPromoTypeController.text,
          'own_promo_mechanism': item.ownPromoMechanismController.text,
          'own_periode': item.ownPeriodeController.text,
          
          'competitor_product_name': item.competitorProductController.text,
          'competitor_normal': item.competitorNormalController.text,
          'competitor_cbp': item.competitorCbpController.text,
          'competitor_outlet': item.competitorOutletController.text,
          'competitor_promo_type': item.competitorPromoTypeController.text,
          'competitor_promo_mechanism': item.competitorPromoMechanismController.text,
          'competitor_periode': item.competitorPeriodeController.text,
        });
        
        ownImages.add(item.ownProductImage);
        competitorImages.add(item.competitorProductImage);
      }
      
      // Send to server
      await _apiService.submitCompetitor(
        widget.storeId,
        widget.visitId,
        itemsData,
        ownImages,
        competitorImages,
      );
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dikirim ke server')),
      );
      
      // Go back to previous screen
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
        title: const Text('Competitor'),
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
                
                // List of competitor items
                Expanded(
                  child: _competitorItems.isEmpty
                      ? const Center(child: Text('Silakan cari produk untuk menambahkan data competitor'))
                      : ListView.builder(
                          itemCount: _competitorItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return _buildCompetitorItemCards(index);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: _competitorItems.isEmpty
            ? Container(height: 56)
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.blue,
                      onPressed: () => _showSendDialog(),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildCompetitorItemCards(int index) {
    final item = _competitorItems[index];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Own
        const SizedBox(height: 16),
        const Text(
          'Product Own',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Center(
                  child: GestureDetector(
                    onTap: () => _pickOwnProductImage(index),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: item.ownProductImage != null
                          ? ClipOval(
                              child: Image.file(
                                item.ownProductImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(height: 4),
                                Text(
                                  'Click to add photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Produk:'),
                    TextField(
                      controller: item.ownProductController,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Prices
                Row(
                  children: [
                    // RBP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga RBP:'),
                          TextField(
                            controller: item.ownRbpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // CBP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga CBP:'),
                          TextField(
                            controller: item.ownCbpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Outlet
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga Outlet:'),
                          TextField(
                            controller: item.ownOutletController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Promo Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promo type:'),
                    DropdownButtonFormField<String>(
                      value: item.ownPromoTypeController.text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      items: _promoTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            item.ownPromoTypeController.text = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mekanisme Promo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mekanisme Promo:'),
                    DropdownButtonFormField<String>(
                      value: item.ownPromoMechanismController.text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      items: _promoMechanisms.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            item.ownPromoMechanismController.text = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Periode
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periode:'),
                    InkWell(
                      onTap: () => _selectPeriod(item.ownPeriodeController),
                      child: TextField(
                        controller: item.ownPeriodeController,
                        enabled: false,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Product Competitor
        const SizedBox(height: 24),
        const Text(
          'Product Competitor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Center(
                  child: GestureDetector(
                    onTap: () => _pickCompetitorProductImage(index),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: item.competitorProductImage != null
                          ? ClipOval(
                              child: Image.file(
                                item.competitorProductImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(height: 4),
                                Text(
                                  'Click to add photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Produk:'),
                    TextField(
                      controller: item.competitorProductController,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Prices
                Row(
                  children: [
                    // Normal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga Normal:'),
                          TextField(
                            controller: item.competitorNormalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // CBP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga CBP:'),
                          TextField(
                            controller: item.competitorCbpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Outlet
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga Outlet:'),
                          TextField(
                            controller: item.competitorOutletController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Promo Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promo type:'),
                    DropdownButtonFormField<String>(
                      value: item.competitorPromoTypeController.text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      items: _promoTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            item.competitorPromoTypeController.text = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mekanisme Promo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mekanisme Promo:'),
                    DropdownButtonFormField<String>(
                      value: item.competitorPromoMechanismController.text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      items: _promoMechanisms.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            item.competitorPromoMechanismController.text = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Periode
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periode:'),
                    InkWell(
                      onTap: () => _selectPeriod(item.competitorPeriodeController),
                      child: TextField(
                        controller: item.competitorPeriodeController,
                        enabled: false,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Model untuk menyimpan item competitor beserta controller-nya
class CompetitorItem {
  final Product product;
  File? ownProductImage;
  File? competitorProductImage;
  
  // Own product controllers
  final TextEditingController ownProductController;
  final TextEditingController ownRbpController;
  final TextEditingController ownCbpController;
  final TextEditingController ownOutletController;
  final TextEditingController ownPromoTypeController;
  final TextEditingController ownPromoMechanismController;
  final TextEditingController ownPeriodeController;
  
  // Competitor product controllers
  final TextEditingController competitorProductController;
  final TextEditingController competitorNormalController;
  final TextEditingController competitorCbpController;
  final TextEditingController competitorOutletController;
  final TextEditingController competitorPromoTypeController;
  final TextEditingController competitorPromoMechanismController;
  final TextEditingController competitorPeriodeController;
  
  CompetitorItem({
    required this.product,
    this.ownProductImage,
    this.competitorProductImage,
    required this.ownProductController,
    required this.ownRbpController,
    required this.ownCbpController,
    required this.ownOutletController,
    required this.ownPromoTypeController,
    required this.ownPromoMechanismController,
    required this.ownPeriodeController,
    required this.competitorProductController,
    required this.competitorNormalController,
    required this.competitorCbpController,
    required this.competitorOutletController,
    required this.competitorPromoTypeController,
    required this.competitorPromoMechanismController,
    required this.competitorPeriodeController,
  });
}
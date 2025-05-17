import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/database/database_helper.dart' as db; // Alias to avoid conflict
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'api/competitor_api_service.dart';
import '../../../utils/connectivity_utils.dart';
import '../../../utils/logger.dart';
import '../../../widget/search_bar_widget.dart';
import 'package:intl/intl.dart';

class CompetitorScreen extends StatefulWidget {
  
  const CompetitorScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<CompetitorScreen> createState() => _CompetitorScreenState();
}

class _CompetitorScreenState extends State<CompetitorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CompetitorApiService _apiService = CompetitorApiService();
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];
  List<CompetitorItem> _competitorItems = [];
  List<OwnItem> _OwnItems = [];
  
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
      // Dispose all text controller
      item.competitorProductController.dispose();
      item.competitorNormalController.dispose();
      item.competitorCbpController.dispose();
      item.competitorOutletController.dispose();
      item.competitorPromoTypeController.dispose();
      item.competitorPromoMechanismController.dispose();
      item.competitorPeriodeController.dispose();
    }

    for (var item in _OwnItems) {
      // Dispose all text controllers
      item.ownProductController.dispose();
      item.ownRbpController.dispose();
      item.ownCbpController.dispose();
      item.ownOutletController.dispose();
      item.ownPromoTypeController.dispose();
      item.ownPromoMechanismController.dispose();
      item.ownPeriodeController.dispose();
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
      final products = await db.DatabaseHelper.instance.getProductSearch(query: keyword);
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
  void _addProduct(ProductModel product) {
    // Periksa apakah produk sudah ada di list
    if (product.category == "own") {
      final existingIndex = _OwnItems.indexWhere((p) => p.product.idProduk == product.idProduk);
      if (existingIndex >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk sudah ditambahkan')),
        );
        return;
      }
      // Create new controllers
      final item = OwnItem(
        product: product,
        ownProductController: TextEditingController(text: product.nama),
        ownRbpController: TextEditingController(text: product.harga?.toString() ?? '10000'),
        ownCbpController: TextEditingController(text: '8000'),
        ownOutletController: TextEditingController(text: '8000'),
        ownPromoTypeController: TextEditingController(text: _promoTypes.first),
        ownPromoMechanismController: TextEditingController(text: _promoMechanisms.first),
        ownPeriodeController: TextEditingController(text: _getDefaultPeriod()),
      );
      
      // Add to list
      setState(() {
        _OwnItems.add(item);
        _searchResults = [];
        _searchController.clear();
      });
    } else {
      final existingIndex = _competitorItems.indexWhere((p) => p.product.idProduk == product.idProduk);
      if (existingIndex >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk sudah ditambahkan')),
        );
        return;
      }
      // Create new controllers
      final item = CompetitorItem(
        product: product,
        competitorProductController: TextEditingController(text: product.nama),
        competitorNormalController: TextEditingController(text: product.harga?.toString() ?? '10000'),
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
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image != null) {
        setState(() {
          _OwnItems[index].ownProductImage = File(image.path);
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
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
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
    if (_OwnItems.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada produk yang ditambahkan')),
      );
      return false;
    }
    
    for (int i = 0; i < _OwnItems.length; i++) {
      final item = _OwnItems[i];
      
      if (item.ownProductController.text.isEmpty ) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama produk own tidak boleh kosong untuk item ${i+1}')),
        );
        return false;
      }
      
      if (item.ownRbpController.text.isEmpty ) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harga produk own tidak boleh kosong untuk item ${i+1}')),
        );
        return false;
      }
    }
    // Competitor items are optional, so no validation needed if empty
    for (int i = 0; i < _competitorItems.length; i++) {
      final item = _competitorItems[i];
      
      if (item.competitorProductController.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama produk competitor tidak boleh kosong untuk item ${i+1}')),
        );
        return false;
      }
      
      if (item.competitorNormalController.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harga produk competitor tidak boleh kosong untuk item ${i+1}')),
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
    
    setState(() { _isLoading = true; });
    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Menyimpan data...")])),
      );
    }
    
    try {
      final user = await SessionManager().getCurrentUser();
      final store = await SessionManager().getStoreData();

      if (user == null || user.idLogin == null || user.idpriciple == null || store == null || store.idOutlet == null) {
        throw Exception("Data user atau toko tidak lengkap.");
      }

      List<Map<String, dynamic>> itemsToSave = [];
      String submissionGroupId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String tglSubmission = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var item in _OwnItems) {
        itemsToSave.add({
          'id_user': user.idLogin,
          'id_outlet': store.idOutlet,
          'outlet_name': store.nama,
          'id_principle': user.idpriciple,
          'id_product': item.product.idProduk,
          'nama_produk': item.ownProductController.text,
          'category_product': 'own',
          'harga_rbp': item.ownRbpController.text,
          'harga_cbp': item.ownCbpController.text,
          'harga_outlet': item.ownOutletController.text,
          'promo_type': item.ownPromoTypeController.text,
          'mekanisme_promo': item.ownPromoMechanismController.text,
          'periode': item.ownPeriodeController.text,
          'image_path': item.ownProductImage?.path,
          'tgl_submission': tglSubmission,
          'submission_group_id': submissionGroupId,
        });
      }

      for (var item in _competitorItems) {
        itemsToSave.add({
          'id_user': user.idLogin,
          'id_outlet': store.idOutlet,
          'outlet_name': store.nama,
          'id_principle': user.idpriciple,
          'id_product': item.product.idProduk,
          'nama_produk': item.competitorProductController.text,
          'category_product': 'comp',
          'harga_rbp': item.competitorNormalController.text, // Assuming normal is RBP for competitor
          'harga_cbp': item.competitorCbpController.text,
          'harga_outlet': item.competitorOutletController.text,
          'promo_type': item.competitorPromoTypeController.text,
          'mekanisme_promo': item.competitorPromoMechanismController.text,
          'periode': item.competitorPeriodeController.text,
          'image_path': item.competitorProductImage?.path,
          'tgl_submission': tglSubmission,
          'submission_group_id': submissionGroupId,
        });
      }

      bool success = await _apiService.saveCompetitorDataOffline(itemsToSave);
      
      if(mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
          );
          Navigator.pop(context); // Go back
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data secara lokal')),
        );
      }
    } catch (e) {
      _logger.e("CompetitorScreen", "Error sending offline: $e");
      if(mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  // Kirim data online
  Future<void> _sendOnline() async {
    if (!_validateData()) {
      return;
    }
    
    setState(() { _isLoading = true; });
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
        );
        setState(() { _isLoading = false; });
      }
      return;
    }
    
    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data...")])),
      );
    }
    
    try {
      final user = await SessionManager().getCurrentUser();
      final store = await SessionManager().getStoreData();

      if (user == null || user.idLogin == null || user.idpriciple == null || store == null || store.idOutlet == null) {
        throw Exception("Data user atau toko tidak lengkap.");
      }

      List<Map<String, dynamic>> promoItemsData = [];
      List<File?> images = [];
      String tglSubmission = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var item in _OwnItems) {
        promoItemsData.add({
          'nama_produk': item.ownProductController.text,
          'id_product': item.product.idProduk,
          'id_user': user.idLogin,
          'id_outlet': store.idOutlet,
          'id_principle': user.idpriciple,
          'category_product': 'own',
          'harga_rbp': item.ownRbpController.text,
          'harga_cbp': item.ownCbpController.text,
          'harga_outlet': item.ownOutletController.text,
          'promo_type': item.ownPromoTypeController.text,
          'mekanisme_promo': item.ownPromoMechanismController.text,
          'periode': item.ownPeriodeController.text,
          'tgl': tglSubmission,
        });
        images.add(item.ownProductImage);
      }

      for (var item in _competitorItems) {
         promoItemsData.add({
          'nama_produk': item.competitorProductController.text,
          'id_product': item.product.idProduk,
          'id_user': user.idLogin,
          'id_outlet': store.idOutlet,
          'id_principle': user.idpriciple,
          'category_product': 'comp',
          'harga_rbp': item.competitorNormalController.text, // API field is harga_rbp
          'harga_cbp': item.competitorCbpController.text,
          'harga_outlet': item.competitorOutletController.text,
          'promo_type': item.competitorPromoTypeController.text,
          'mekanisme_promo': item.competitorPromoMechanismController.text,
          'periode': item.competitorPeriodeController.text,
          'tgl': tglSubmission,
        });
        images.add(item.competitorProductImage);
      }

      bool success = await _apiService.submitCompetitorDataOnline(promoItemsData, images);
      
      if(mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dikirim ke server')),
          );
          Navigator.pop(context); // Go back
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim data ke server')),
        );
      }

    } catch (e) {
      _logger.e("CompetitorScreen", "Error sending online: $e");
      if(mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
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
          ? const Center(child: CircularProgressIndicator()) // This is covered by the dialog now
          : SingleChildScrollView(
            child: Column(
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
                          title: Text(product.nama ?? ''),
                          subtitle: Text('Code: ${product.kode ?? ''} (${product.category})'),
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
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: const Text(
                            'Product Own',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _OwnItems.isEmpty
                      ? const Center(child: Text('Silakan cari produk untuk menambahkan data own'))
                      : ListView.builder(
                        shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _OwnItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return _buildOwnItemCards(index);
                          },
                        ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: const Text(
                            'Product Competitor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _competitorItems.isEmpty
                      ? const Center(child: Text('Silakan cari produk untuk menambahkan data competitor'))
                      : ListView.builder(
                        shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _competitorItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return _buildCompetitorItemCards(index);
                          },
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: (_OwnItems.isNotEmpty || _competitorItems.isNotEmpty) && !_isLoading
        ? FloatingActionButton.extended(
            onPressed: _showSendDialog,
            heroTag: null, // Ensure this unique heroTag is present
            icon: const Icon(Icons.send),
            label: const Text('KIRIM DATA'),
            backgroundColor: AppColors.primary,
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _removeProduct(int index, String type) {

    if (type == "own") {
        setState(() {
          _OwnItems.removeAt(index);
          _searchController.clear();
        });
    } else {
        setState(() {
          _competitorItems.removeAt(index);
          _searchController.clear();
        });
    }
  }
  
  Widget _buildCompetitorItemCards(int index) {
    final item = _competitorItems[index];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    alignment: Alignment.topRight,
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _removeProduct(index, "comp"),
                  )
                ),
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
                      readOnly: true,
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
        //const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOwnItemCards(int index) {
    final item = _OwnItems[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Own
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

                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    alignment: Alignment.topRight,
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _removeProduct(index, "own"),
                  )
                ),

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
                      readOnly: true,
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
      ],
    );
  }
}

// Model untuk menyimpan item competitor beserta controller-nya
class CompetitorItem {
  final ProductModel product;
  File? ownProductImage;
  File? competitorProductImage;
  
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
    required this.competitorProductController,
    required this.competitorNormalController,
    required this.competitorCbpController,
    required this.competitorOutletController,
    required this.competitorPromoTypeController,
    required this.competitorPromoMechanismController,
    required this.competitorPeriodeController,
  });
}

class OwnItem {
  final ProductModel product;
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
  
  OwnItem({
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
  });
}
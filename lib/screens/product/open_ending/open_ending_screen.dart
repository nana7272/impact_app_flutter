// lib/screens/product/open_ending_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/product/open_ending/api/open_ending_api_service.dart';
import 'package:impact_app/screens/setting/model/outlet_model.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';
import '../../../themes/app_colors.dart';
import '../../../utils/connectivity_utils.dart';
import '../../../widget/search_bar_widget.dart';

class OpenEndingScreen extends StatefulWidget {
  final String storeId; // Sebenarnya ini idOutlet dari SessionManager
  final String visitId; // Mungkin tidak relevan untuk Open Ending offline list
  
  const OpenEndingScreen({
    Key? key,
    required this.storeId,
    required this.visitId,
  }) : super(key: key);

  @override
  State<OpenEndingScreen> createState() => _OpenEndingScreenState();
}

class _OpenEndingScreenState extends State<OpenEndingScreen> {
  final OpenEndingApiService _apiService = OpenEndingApiService();
  final Logger _logger = Logger();
  final String _tag = 'OpenEndingScreen';
  
  final TextEditingController _searchController = TextEditingController();
  final List<ProductModel> _selectedProducts = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];

  final Map<String, TextEditingController> _openControllers = {};
  final Map<String, TextEditingController> _inControllers = {};
  final Map<String, TextEditingController> _endingControllers = {};
  final Map<String, TextEditingController> _sellOutControllers = {};
  final Map<String, TextEditingController> _ketControllers = {};
  final Map<String, TextEditingController> _selvingControllers = {};
  final Map<String, TextEditingController> _expiredDateControllers = {};
  final Map<String, TextEditingController> _listingControllers = {};
  final Map<String, bool> _stockReturnCheckValues = {};
  final Map<String, TextEditingController> _returnQtyControllers = {};
  final Map<String, TextEditingController> _returnReasonControllers = {};
  final Map<String, bool> _stockExpiredValues = {};

  Store? _currentOutlet; // Untuk menyimpan data outlet dari session

  @override
  void initState() {
    super.initState();
    _loadOutletData(); // Panggil method untuk memuat data outlet
  }

  Future<void> _loadOutletData() async {
    _currentOutlet = await SessionManager().getStoreData();
    if (_currentOutlet == null) {
      _logger.e(_tag, "Gagal memuat data outlet dari session.");
      // Handle jika data outlet tidak ditemukan, mungkin tampilkan pesan atau cegah input
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data toko. Silakan coba lagi.')),
        );
        // Navigator.pop(context); // Contoh: kembali jika data toko penting
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _openControllers.values.forEach((c) => c.dispose());
    _inControllers.values.forEach((c) => c.dispose());
    _endingControllers.values.forEach((c) => c.dispose());
    _sellOutControllers.values.forEach((c) => c.dispose());
    _ketControllers.values.forEach((c) => c.dispose());
    _selvingControllers.values.forEach((c) => c.dispose());
    _expiredDateControllers.values.forEach((c) => c.dispose());
    _listingControllers.values.forEach((c) => c.dispose());
    _returnQtyControllers.values.forEach((c) => c.dispose());
    _returnReasonControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _searchProducts(String keyword) async {
    // ... (implementasi pencarian produk yang sudah ada)
     if (keyword.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() { _isSearching = true; });
    try {
      final products = await DatabaseHelper.instance.getProductSearch(query: keyword);
      setState(() { _searchResults = products; _isSearching = false; });
    } catch (e) {
      setState(() { _isSearching = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mencari produk: $e')));
    }
  }

  void _addProduct(ProductModel product) {
    // ... (implementasi tambah produk yang sudah ada)
    final existingIndex = _selectedProducts.indexWhere((p) => p.idProduk == product.idProduk);
    if (existingIndex >= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk sudah ditambahkan')));
      return;
    }
    setState(() {
      _selectedProducts.add(product);
      _searchResults = [];
      _searchController.clear();
      _openControllers[product.idProduk!] = TextEditingController();
      _inControllers[product.idProduk!] = TextEditingController();
      _endingControllers[product.idProduk!] = TextEditingController();
      _sellOutControllers[product.idProduk!] = TextEditingController();
      _ketControllers[product.idProduk!] = TextEditingController();
      _selvingControllers[product.idProduk!] = TextEditingController();
      _expiredDateControllers[product.idProduk!] = TextEditingController();
      _listingControllers[product.idProduk!] = TextEditingController();
      _stockReturnCheckValues[product.idProduk!] = false;
      _returnQtyControllers[product.idProduk!] = TextEditingController();
      _returnReasonControllers[product.idProduk!] = TextEditingController();
      _stockExpiredValues[product.idProduk!] = false;
    });
  }

  void _removeProduct(int index) {
    // ... (implementasi hapus produk yang sudah ada)
    final productId = _selectedProducts[index].idProduk!;
    setState(() {
      _openControllers[productId]?.dispose(); _inControllers[productId]?.dispose(); /* ... semua controller ... */
      _openControllers.remove(productId); _inControllers.remove(productId); /* ... semua controller ... */
      _stockReturnCheckValues.remove(productId); _stockExpiredValues.remove(productId);
      _selectedProducts.removeAt(index);
    });
  }

  // MODIFIKASI: Menyiapkan data untuk disimpan ke DB Lokal
  Future<List<Map<String, dynamic>>> _prepareDataForLocalDb() async {
    List<Map<String, dynamic>> itemsForDb = [];
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final user = await SessionManager().getCurrentUser();
    // _currentOutlet sudah di-load di initState

    if (user == null || _currentOutlet == null) {
      _logger.e(_tag, "User or Outlet data is null. Cannot prepare data for local DB.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data User atau Toko tidak ditemukan. Gagal menyimpan.')),
        );
      }
      return []; // Kembalikan list kosong jika data penting tidak ada
    }

    final String userId = user.idLogin ?? '';
    final int idPrinciple = int.tryParse(user.idpriciple ?? '0') ?? 0;
    final String outletId = _currentOutlet!.idOutlet ?? '';
    final String outletName = _currentOutlet!.nama ?? 'Outlet Tidak Diketahui';

    for (var product in _selectedProducts) {
      final productId = product.idProduk!;
      final String productName = product.nama ?? 'Produk Tidak Diketahui';

      itemsForDb.add({
        "id_principle": idPrinciple,
        "id_outlet": outletId, // Menggunakan outletId dari _currentOutlet
        "outlet_name": outletName, // SIMPAN NAMA OUTLET
        "id_product": productId, 
        "product_name": productName, // SIMPAN NAMA PRODUK
        "sf": int.tryParse(_openControllers[productId]?.text ?? '0') ?? 0,
        "si": int.tryParse(_inControllers[productId]?.text ?? '0') ?? 0,
        "sa": int.tryParse(_endingControllers[productId]?.text ?? '0') ?? 0,
        "so": int.tryParse(_sellOutControllers[productId]?.text ?? '0') ?? 0,
        "ket": _ketControllers[productId]?.text ?? '',
        "sender": userId, // API mengharapkan int, tapi DB bisa TEXT. Sesuaikan jika perlu.
        "tgl": currentDate,
        "selving": _selvingControllers[productId]?.text ?? '',
        "expired": _expiredDateControllers[productId]?.text ?? '', 
        "listing": _listingControllers[productId]?.text ?? '',
        "return": _stockReturnCheckValues[productId] == true ? (int.tryParse(_returnQtyControllers[productId]?.text ?? '0') ?? 0) : 0,
        "return_reason": _stockReturnCheckValues[productId] == true ? (_returnReasonControllers[productId]?.text) : null,
        "is_synced": 0, // Tandai sebagai belum sinkron
      });
    }
    return itemsForDb;
  }
  
  // MODIFIKASI: Menyiapkan data untuk dikirim ke API (payload tetap sama)
  Future<List<Map<String, dynamic>>> _prepareDataForApiSync() async {
    List<Map<String, dynamic>> items = [];
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final user = await SessionManager().getCurrentUser();
     // _currentOutlet sudah di-load di initState

    if (user == null || _currentOutlet == null) {
      _logger.e(_tag, "User or Outlet data is null. Cannot prepare data for API sync.");
      return [];
    }

    final String userId = user.idLogin ?? '';
    final int idPrinciple = int.tryParse(user.idpriciple ?? '0') ?? 0;
    final String outletId = _currentOutlet!.idOutlet ?? ''; // Ambil dari _currentOutlet

    for (var product in _selectedProducts) {
      final productIdValue = product.idProduk!;
      items.add({
        "id_principle": idPrinciple,
        "id_outlet": int.tryParse(outletId) ?? 0, // API mengharapkan int
        "id_product": int.tryParse(productIdValue) ?? 0, // API mengharapkan int
        "SF": int.tryParse(_openControllers[productIdValue]?.text ?? '0') ?? 0,
        "SI": int.tryParse(_inControllers[productIdValue]?.text ?? '0') ?? 0,
        "SA": int.tryParse(_endingControllers[productIdValue]?.text ?? '0') ?? 0,
        "SO": int.tryParse(_sellOutControllers[productIdValue]?.text ?? '0') ?? 0,
        "ket": _ketControllers[productIdValue]?.text ?? '',
        "sender": int.tryParse(userId) ?? 0, // API expects int
        "tgl": currentDate,
        "selving": _selvingControllers[productIdValue]?.text ?? '',
        "expired": _expiredDateControllers[productIdValue]?.text ?? '', 
        "listing": _listingControllers[productIdValue]?.text ?? '',
        "return": _stockReturnCheckValues[productIdValue] == true ? (int.tryParse(_returnQtyControllers[productIdValue]?.text ?? '0') ?? 0) : 0,
        "return_reason": _stockReturnCheckValues[productIdValue] == true ? (_returnReasonControllers[productIdValue]?.text) : null,
        // "status" dan "is_synced" tidak dikirim ke API
      });
    }
    _logger.d(_tag, "Prepared data for API: $items");
    return items;
  }


  void _showSendDialog() {
    // ... (implementasi dialog yang sudah ada)
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Kirim data menggunakan metode?'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _sendOffline(); }, child: const Text('Offline (Local)')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _sendOnline(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Online (Server)')),
        ],
      ),
    );
  }

  Future<void> _sendOffline() async {
    if (!_validateData()) return; // Validasi sebelum menyimpan offline
    if (_currentOutlet == null) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data toko tidak termuat, tidak bisa menyimpan offline.')));
       return;
    }

    setState(() { _isLoading = true; });
    if (mounted) showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final List<Map<String, dynamic>> itemsToSave = await _prepareDataForLocalDb();
      if (itemsToSave.isEmpty && _selectedProducts.isNotEmpty) { // Ada produk dipilih tapi gagal siapkan data
         if (mounted) Navigator.pop(context); // Tutup loading
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyiapkan data untuk disimpan lokal.')));
         setState(() { _isLoading = false; });
         return;
      }

      int successCount = 0;
      for (var localDbItem in itemsToSave) {
        await DatabaseHelper.instance.insertOpenEndingData(localDbItem);
        successCount++;
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (successCount == itemsToSave.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan secara lokal')));
          Navigator.pop(context); 
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sebagian data gagal disimpan lokal ($successCount dari ${itemsToSave.length})')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      _logger.e(_tag, "Error sending offline: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyimpan offline: $e')));
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _sendOnline() async {
    if (!_validateData()) return; // Validasi sebelum mengirim online
     if (_currentOutlet == null) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data toko tidak termuat, tidak bisa mengirim online.')));
       return;
    }

    setState(() { _isLoading = true; });
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada koneksi internet.')));
      return;
    }

    if (mounted) showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final List<Map<String, dynamic>> openEndingItemsForApi = await _prepareDataForApiSync();
       if (openEndingItemsForApi.isEmpty && _selectedProducts.isNotEmpty) {
         if (mounted) Navigator.pop(context); // Tutup loading
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyiapkan data untuk dikirim ke server.')));
         setState(() { _isLoading = false; });
         return;
      }

      bool success = await _apiService.submitOpenEndingData(openEndingItemsForApi);
      if (mounted) Navigator.pop(context); 

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil dikirim ke server')));
          Navigator.pop(context); 
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim data ke server')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      _logger.e(_tag, "Error sending online: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengirim online: $e')));
    }
    setState(() { _isLoading = false; });
  }

  bool _validateData() {
    // ... (implementasi validasi yang sudah ada)
    if (_currentOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data toko belum termuat. Tidak bisa validasi.')));
      return false;
    }
    for (var product in _selectedProducts) {
      final productId = product.idProduk!;
      if (_openControllers[productId]!.text.isEmpty ||
          _inControllers[productId]!.text.isEmpty ||
          _endingControllers[productId]!.text.isEmpty ||
          _sellOutControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi Open, In, Ending, dan Sell Out untuk ${product.nama}')));
        return false;
      }
      if ((_stockExpiredValues[productId] ?? false) && _expiredDateControllers[productId]!.text.isEmpty) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi Expired Date untuk ${product.nama} jika Stock Expired dicentang')));
        return false;
      }
      if ((_stockReturnCheckValues[productId] ?? false) && _returnQtyControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi Return Qty untuk ${product.nama} jika Stock Return dicentang')));
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI build method yang sudah ada, tidak ada perubahan signifikan di sini selain memastikan _validateData dipanggil sebelum _showSendDialog)
    // Pastikan tombol send memanggil _validateData() dulu.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Ending'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.grey[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: "Search here",
              onChanged: _searchProducts,
              onScanPressed: () { /* Handle scan */ },
            ),
          ),
          if (_isSearching) const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    leading: product.gambar != null ? Image.network(product.gambar!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported)) : const Icon(Icons.inventory),
                    title: Text(product.nama ?? ''),
                    subtitle: Text('Kode: ${product.kode}'),
                    trailing: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.success), onPressed: () => _addProduct(product)),
                  );
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Tidak ada produk ditemukan')))
          else const SizedBox(),
          Expanded(
            child: _selectedProducts.isEmpty
                ? const Center(child: Text('Tambahkan produk dengan mencari di kolom pencarian.'))
                : ListView.builder(
                    itemCount: _selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedProducts[index];
                      final productId = product.idProduk!;
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column( // Mengubah Row menjadi Column untuk header produk
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row( // Row untuk nama produk dan tombol delete
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.nama?.toUpperCase() ?? '',
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
                              Container( // Container untuk field input
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _buildInputField('Open', _openControllers[productId]!, width: (MediaQuery.of(context).size.width - 60) / 3), // Adjusted width calculation
                                        _buildInputField('In', _inControllers[productId]!, width: (MediaQuery.of(context).size.width - 60) / 3),
                                        _buildInputField('Ending', _endingControllers[productId]!, width: (MediaQuery.of(context).size.width - 60) / 3),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildInputField('Sell Out', _sellOutControllers[productId]!, width: double.infinity, singleLine: true),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildInputField('Keterangan', _ketControllers[productId]!, width: double.infinity, singleLine: true, keyboardType: TextInputType.text)),
                                        const SizedBox(width: 8),
                                        Expanded(child: _buildInputField('Selving', _selvingControllers[productId]!, width: double.infinity, singleLine: true, keyboardType: TextInputType.text)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      title: const Text("Stock Return"),
                                      value: _stockReturnCheckValues[productId] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          _stockReturnCheckValues[productId] = value ?? false;
                                          if (!(value ?? false)) { 
                                            _returnQtyControllers[productId]?.clear();
                                            _returnReasonControllers[productId]?.clear();
                                          }
                                        });
                                      },
                                    ),
                                    if (_stockReturnCheckValues[productId] ?? false) ...[
                                      Row(
                                        children: [
                                          Expanded(child: _buildInputField('Return Qty', _returnQtyControllers[productId]!, width: double.infinity, singleLine: true)),
                                          const SizedBox(width: 8),
                                          Expanded(child: _buildInputField('Return Reason', _returnReasonControllers[productId]!, width: double.infinity, singleLine: true, keyboardType: TextInputType.text)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      title: const Text("Stock Expired (Flag)"),
                                      value: _stockExpiredValues[productId] ?? false,
                                      onChanged: (value) {
                                        setState(() { _stockExpiredValues[productId] = value ?? false; });
                                        if (!(value ?? false)) { _expiredDateControllers[productId]?.clear(); }
                                      },
                                    ),
                                    if (_stockExpiredValues[productId] ?? false) ...[
                                      _buildDateField('Expired Date (YYYY-MM-DD)', _expiredDateControllers[productId]!),
                                      const SizedBox(height: 10),
                                    ],
                                    _buildInputField('Listing', _listingControllers[productId]!, width: double.infinity, singleLine: true, keyboardType: TextInputType.text),
                                    const SizedBox(height: 10),
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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada produk yang dipilih')));
            return;
          }
          if (_validateData()) { // Panggil validasi di sini
            _showSendDialog();
          }
        },
        backgroundColor: AppColors.primary, // Menggunakan AppColors.primary
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {required double width, bool singleLine = false, TextInputType keyboardType = TextInputType.number}) {
    // ... (implementasi buildInputField yang sudah ada)
    return Container(
      width: singleLine ? null : width, 
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType, // Hanya angka bulat
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    // ... (implementasi buildDateField yang sudah ada)
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: true, // Agar keyboard tidak muncul
            decoration: const InputDecoration(hintText: 'YYYY-MM-DD', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), suffixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode()); 
              DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
              if(pickedDate != null ){ controller.text = DateFormat('yyyy-MM-dd').format(pickedDate); }
            },
          ),
        ],
      ),
    );
  }
}

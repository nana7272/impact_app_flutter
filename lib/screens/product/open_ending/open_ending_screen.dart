import 'package:flutter/material.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/api/open_ending_api_service.dart';
import 'package:impact_app/screens/setting/model/product_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';
import '../../../themes/app_colors.dart';
import '../../../utils/connectivity_utils.dart';
// import '../../../models/product_sales_model.dart'; // Tidak digunakan lagi secara langsung di sini
import '../../../widget/search_bar_widget.dart';
// import 'package:impact_app/utils/session_manager.dart'; // Jika Anda akan mengambil userId dari session

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
  final OpenEndingApiService _apiService = OpenEndingApiService();
  final Logger _logger = Logger();
  final String _tag = 'OpenEndingScreen';
  
  final TextEditingController _searchController = TextEditingController();
  final List<ProductModel> _selectedProducts = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];

  // Controllers untuk setiap produk
  final Map<String, TextEditingController> _openControllers = {};
  final Map<String, TextEditingController> _inControllers = {};
  final Map<String, TextEditingController> _endingControllers = {};
  final Map<String, TextEditingController> _sellOutControllers = {};
  final Map<String, TextEditingController> _ketControllers = {};
  final Map<String, TextEditingController> _selvingControllers = {};
  final Map<String, TextEditingController> _expiredDateControllers = {};
  final Map<String, TextEditingController> _listingControllers = {};
  final Map<String, bool> _stockReturnCheckValues = {}; // For the checkbox
  final Map<String, TextEditingController> _returnQtyControllers = {};
  final Map<String, TextEditingController> _returnReasonControllers = {};
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
    for (var controller in _ketControllers.values) {
      controller.dispose();
    }
    for (var controller in _selvingControllers.values) {
      controller.dispose();
    }
    for (var controller in _expiredDateControllers.values) {
      controller.dispose();
    }
    for (var controller in _listingControllers.values) {
      controller.dispose();
    }
    for (var controller in _returnQtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _returnReasonControllers.values) {
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
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mencari produk: $e')),
        );
      }
    }
  }

  // Menambahkan produk ke list
  void _addProduct(ProductModel product) {
    // Periksa apakah produk sudah ada di list
    final existingIndex = _selectedProducts.indexWhere((p) => p.idProduk == product.idProduk);
    if (existingIndex >= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk sudah ditambahkan')),
        );
      }
      return;
    }

    setState(() {
      _selectedProducts.add(product);
      _searchResults = [];
      _searchController.clear();
      
      // Inisialisasi controllers untuk produk baru
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

  // Menghapus produk dari list
  void _removeProduct(int index) {
    final productId = _selectedProducts[index].idProduk!;
    
    setState(() {
      // Hapus controllers
      _openControllers[productId]?.dispose();
      _inControllers[productId]?.dispose();
      _endingControllers[productId]?.dispose();
      _sellOutControllers[productId]?.dispose();
      _ketControllers[productId]?.dispose();
      _selvingControllers[productId]?.dispose();
      _expiredDateControllers[productId]?.dispose();
      _listingControllers[productId]?.dispose();
      _returnQtyControllers[productId]?.dispose();
      _returnReasonControllers[productId]?.dispose();
      
      _openControllers.remove(productId);
      _inControllers.remove(productId);
      _endingControllers.remove(productId);
      _sellOutControllers.remove(productId);
      _ketControllers.remove(productId);
      _selvingControllers.remove(productId);
      _expiredDateControllers.remove(productId);
      _listingControllers.remove(productId);
      _stockReturnCheckValues.remove(productId);
      _returnQtyControllers.remove(productId);
      _returnReasonControllers.remove(productId);
      _stockExpiredValues.remove(productId);
      
      _selectedProducts.removeAt(index);
    });
  }

  Future<List<Map<String, dynamic>>> _prepareDataForSync() async {
    List<Map<String, dynamic>> items = [];
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final user = await SessionManager().getCurrentUser();
    final outlet = await SessionManager().getStoreData();

    // final String? userId = await SessionManager().getUserId(); // Implement SessionManager().getUserId()
    final String userId = user?.idLogin ?? ''; // Placeholder for sender/userId, ganti dengan user ID yang sebenarnya
    final int idPrinciple = int.tryParse(user?.idpriciple ?? '0') ?? 0; // Placeholder for id_principle, ganti dengan ID principle yang sebenarnya

    for (var product in _selectedProducts) {
      final productId = product.idProduk!;
      items.add({
        "id_principle": idPrinciple,
        "id_outlet": int.tryParse(outlet?.idOutlet ?? "0") ?? 0,
        "id_product": int.tryParse(productId) ?? 0,
        "SF": int.tryParse(_openControllers[productId]?.text ?? '0') ?? 0,
        "SI": int.tryParse(_inControllers[productId]?.text ?? '0') ?? 0,
        "SA": int.tryParse(_endingControllers[productId]?.text ?? '0') ?? 0,
        "SO": int.tryParse(_sellOutControllers[productId]?.text ?? '0') ?? 0,
        "ket": _ketControllers[productId]?.text ?? '',
        "sender": int.tryParse(userId) ?? 0, // API expects int
        "tgl": currentDate,
        "selving": _selvingControllers[productId]?.text ?? '',
        "expired": _expiredDateControllers[productId]?.text ?? '', // Ensure YYYY-MM-DD format
        "listing": _listingControllers[productId]?.text ?? '',
        "return": _stockReturnCheckValues[productId] == true ? (int.tryParse(_returnQtyControllers[productId]?.text ?? '0') ?? 0) : 0,
        "return_reason": _stockReturnCheckValues[productId] == true ? (_returnReasonControllers[productId]?.text) : null,
      });
    }
    return items;
  }

  Map<String, dynamic> _prepareDataForLocalDb(Map<String, dynamic> apiItem) {
    Map<String, dynamic> localItem = Map.from(apiItem);
    //localItem.remove('status'); 
    localItem['is_synced'] = 0; 
    // Jika Anda menggunakan id_local yang unik untuk setiap item di DB lokal:
    // localItem['id_local'] = Uuid().v4(); // Anda perlu package uuid
    return localItem;
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

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final List<Map<String, dynamic>> openEndingItemsApiFormat = await _prepareDataForSync();
      int successCount = 0;
      for (var apiItem in openEndingItemsApiFormat) {
        final localDbItem = _prepareDataForLocalDb(apiItem);
        await DatabaseHelper.instance.insertOpenEndingData(localDbItem);
        successCount++;
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (successCount == openEndingItemsApiFormat.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan secara lokal')),
          );
          Navigator.pop(context); // Kembali ke layar sebelumnya
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sebagian data gagal disimpan lokal ($successCount dari ${openEndingItemsApiFormat.length})')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _logger.e(_tag, "Error sending offline: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
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

    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada koneksi internet. Gunakan metode offline.')),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final List<Map<String, dynamic>> openEndingItems = await _prepareDataForSync();
      _logger.d(_tag, "Prepared data for API: $openEndingItems");

      bool success = await _apiService.submitOpenEndingData(openEndingItems);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dikirim ke server')),
          );
          Navigator.pop(context); // Kembali ke layar sebelumnya
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim data ke server')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _logger.e(_tag, "Error sending online: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
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
      final productId = product.idProduk!;
      if (_openControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Open untuk ${product.nama}')),
        );
        return false;
      }
      if (_inControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi In untuk ${product.nama}')),
        );
        return false;
      }
      if (_endingControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Ending untuk ${product.nama}')),
        );
        return false;
      }
      if (_sellOutControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Sell Out untuk ${product.nama}')),
        );
        return false;
      }
      if ((_stockExpiredValues[productId] ?? false) && _expiredDateControllers[productId]!.text.isEmpty) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Expired Date untuk ${product.nama}')),
        );
        return false;
      }
      if ((_stockReturnCheckValues[productId] ?? false) && _returnQtyControllers[productId]!.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Return Qty untuk ${product.nama}')),
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
                    leading: product.gambar != null
                        ? Image.network(
                            product.gambar!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.inventory),
                    title: Text(product.nama ?? ''),
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.nama?.toUpperCase() ?? '',
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
                                              _buildInputField('Open', _openControllers[productId]!, width: (MediaQuery.of(context).size.width - 100) / 3.2), // Adjusted width
                                              _buildInputField('In', _inControllers[productId]!, width: (MediaQuery.of(context).size.width - 100) / 3.2),
                                              _buildInputField('Ending', _endingControllers[productId]!, width: (MediaQuery.of(context).size.width - 100) / 3.2),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: AppColors.error),
                                                onPressed: () => _removeProduct(index),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          
                                          _buildInputField('Sell Out', _sellOutControllers[productId]!, width: double.infinity, singleLine: true),
                                          const SizedBox(height: 10),
                                          
                                          Row(
                                            children: [
                                              Expanded(child: _buildInputField('Keterangan', _ketControllers[productId]!, width: double.infinity, singleLine: true)),
                                              const SizedBox(width: 8),
                                              Expanded(child: _buildInputField('Selving', _selvingControllers[productId]!, width: double.infinity, singleLine: true)),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // Row(
                                          //   children: [
                                          //     Expanded(
                                          //       child: _buildDateField('Expired Date (YYYY-MM-DD)', _expiredDateControllers[productId]!),
                                          //     ),
                                          //     const SizedBox(width: 8),
                                          //     Expanded(
                                          //       child: _buildInputField('Listing', _listingControllers[productId]!, width: double.infinity, singleLine: true),
                                          //     ),
                                          //   ],
                                          // ),
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
                                                Expanded(child: _buildInputField('Return Reason', _returnReasonControllers[productId]!, width: double.infinity, singleLine: true)),
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
                                              setState(() {
                                                _stockExpiredValues[productId] = value ?? false;
                                              });
                                              if (!(value ?? false)) { // Clear expired date if unchecked
                                                _expiredDateControllers[productId]?.clear();
                                              }
                                            },
                                          ),
                                          if (_stockExpiredValues[productId] ?? false) ...[
                                            _buildDateField('Expired Date (YYYY-MM-DD)', _expiredDateControllers[productId]!),
                                            const SizedBox(height: 10),
                                          ],
                                          // Listing field (bisa dipindah sesuai kebutuhan layout)
                                          _buildInputField('Listing', _listingControllers[productId]!, width: double.infinity, singleLine: true),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada produk yang dipilih')),
              );
            }
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

  Widget _buildInputField(String label, TextEditingController controller, {required double width, bool singleLine = false}) {
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
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode()); 
              DateTime? pickedDate = await showDatePicker(
                  context: context, initialDate: DateTime.now(),
                  firstDate: DateTime(2000), lastDate: DateTime(2101));
              if(pickedDate != null ){
                controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              }
            },
          ),
        ],
      ),
    );
  }
}

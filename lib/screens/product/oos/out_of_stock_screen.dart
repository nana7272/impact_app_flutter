// lib/screens/oos/out_of_stock_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/models/product_sales_model.dart';
import 'package:impact_app/screens/product/oos/api/oos_api_service.dart';
import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:impact_app/widget/search_bar_widget.dart';
import 'package:intl/intl.dart';

import 'package:impact_app/screens/setting/model/product_model.dart'; // Sesuaikan path ProductModel dari database_helper


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
  final OOSApiService _oosApiService = OOSApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final TextEditingController _searchController = TextEditingController();
  final List<OOSInputProduct> _selectedProducts = [];

  bool _isLoading = false;
  bool _isSearching = false;
  List<ProductSales> _searchResults = []; // Ini akan diisi dari hasil pencarian DB

  // Debouncer sederhana untuk menunda pencarian saat pengguna mengetik
  Debouncer _debouncer = Debouncer(milliseconds: 500);


  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose(); // Jangan lupa dispose debouncer
    for (var product in _selectedProducts) {
      product.quantityController.dispose();
      product.noteController.dispose();
    }
    super.dispose();
  }

  // --- FUNGSI PENCARIAN PRODUK DARI DATABASE LOKAL ---
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() { _isSearching = true; });

    try {
      // Panggil fungsi dari DatabaseHelper
      final List<ProductModel> productsFromDb = await _dbHelper.getProductSearch(query: keyword, limit: 15); // Batasi hasil
      if (!mounted) return;

      setState(() {
        // Mapping dari ProductModel (dari DB) ke ProductSales (untuk UI)
        _searchResults = productsFromDb.map((pModel) {
          // Pastikan ProductSales bisa dibuat dari ProductModel
          // atau lakukan mapping manual field yang dibutuhkan
          return ProductSales(
            id: pModel.idProduk, // Asumsi idProduk adalah String di ProductModel
                                 // dan ProductSales.id juga String.
                                 // Jika ProductModel.idProduk adalah int, ubah jadi pModel.idProduk.toString()
            name: pModel.nama,
            code: pModel.kode,
            // price: double.tryParse(pModel.harga ?? "0"), // Jika ada field harga
          );
        }).toList();
      });
    } catch (e) {
      print("Error searching products from local DB: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mencari produk dari database lokal: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() { _isSearching = false; });
    }
  }

  // Wrapper untuk menggunakan debouncer
  void _onSearchChanged(String keyword) {
    _debouncer.run(() {
      _performSearch(keyword);
    });
  }


  void _addProduct(ProductSales product) {
    int? productIdInt = int.tryParse(product?.id ?? '0');
    if (productIdInt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Produk tidak valid.')),
        );
        return;
    }

    final existingIndex = _selectedProducts.indexWhere((p) => p.product.id == product.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ditambahkan')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedProducts.add(OOSInputProduct(
        product: product,
        quantityController: TextEditingController(),
        noteController: TextEditingController(),
      ));
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  bool _validateData() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada produk OOS yang dipilih.')),
      );
      return false;
    }
    for (int i = 0; i < _selectedProducts.length; i++) {
      final item = _selectedProducts[i];
      if (!item.isEmpty && item.quantityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon isi Quantity untuk ${item.product.name ?? 'produk tanpa nama'} jika statusnya Tersedia.')),
        );
        return false;
      }
      if (!item.isEmpty && (int.tryParse(item.quantityController.text.trim()) ?? 0) <= 0) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity untuk ${item.product.name ?? 'produk tanpa nama'} harus lebih dari 0 jika Tersedia.')),
        );
        return false;
      }
    }
    return true;
  }

  void _showSendDialog() {
    if (!_validateData()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Data OOS'),
        content: const Text('Pilih metode pengiriman data:'),
        actions: <Widget>[
          TextButton(
            child: const Text('Simpan Offline'),
            onPressed: () {
              Navigator.of(context).pop();
              _sendData(isOnline: false);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
            ),
            child: const Text('Kirim ke Server'),
            onPressed: () {
              Navigator.of(context).pop();
              _sendData(isOnline: true);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendData({required bool isOnline}) async {
    // ... (Isi fungsi _sendData sama seperti di respons sebelumnya, tidak ada perubahan di sini) ...
    // Pastikan field idPrinciple dan currentUserId (sender) diambil dari widget:
    // idPrinciple: widget.idPrinciple,
    // sender: widget.currentUserId,
    // Dan idProduct di-parse dari product.id yang tipenya String
    // idProduct: productId, // (dimana productId adalah hasil int.tryParse(inputProduct.product.id))

    if (!mounted) return;
    setState(() { _isLoading = true; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Memproses data..."),
              ],
            ),
          ),
        );
      },
    );

    final outlet = await SessionManager().getStoreData();
    int? idOutlet = int.tryParse(outlet?.idOutlet ?? '0');
    if (idOutlet == null) {
      if (mounted) Navigator.pop(context); 
      if (mounted) setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID Outlet tidak valid untuk pengiriman.')),
        );
      }
      return;
    }

    List<OOSItem> oosItemsToProcess = [];
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var inputProduct in _selectedProducts) {
      int? productId = int.tryParse(inputProduct.product.id ?? '0');
      if (productId == null) {
        print("Skipping product with invalid ID: ${inputProduct.product.name}");
        continue;
      }

      final user = await SessionManager().getCurrentUser();
      //final outlet = await SessionManager().getStoreData();

      oosItemsToProcess.add(OOSItem(
        idPrinciple: int.tryParse(user?.idpriciple ?? '0') ?? 0,
        idOutlet: idOutlet,
        idProduct: productId,
        productName: inputProduct.product.name ?? 'Unknown Product',
        quantity: inputProduct.isEmpty ? 0 : (int.tryParse(inputProduct.quantityController.text.trim()) ?? 0),
        ket: inputProduct.noteController.text.trim(),
        type: "REGULAR", 
        outletName: outlet?.nama,
        sender: int.tryParse(user?.idLogin ?? '0') ?? 0,
        tgl: currentDate,
        isEmpty: inputProduct.isEmpty,
        isSynced: isOnline ? 1 : 0, 
      ));
    }

    if (oosItemsToProcess.isEmpty && _selectedProducts.isNotEmpty) {
       if (mounted) Navigator.pop(context); 
       if (mounted) setState(() { _isLoading = false; });
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Tidak ada produk dengan ID valid untuk diproses.')),
        );
       }
      return;
    }
    if (oosItemsToProcess.isEmpty && _selectedProducts.isEmpty) {
        if (mounted) Navigator.pop(context); 
        if (mounted) setState(() { _isLoading = false; });
        return;
    }

    bool success = false;
    String message = "";

    try {
      if (isOnline) {
        bool hasInternet = await ConnectivityUtils.checkInternetConnection();
        if (hasInternet) {
          success = await _oosApiService.sendOOSData(oosItemsToProcess);
          message = success ? 'Data OOS berhasil dikirim ke server.' : 'Gagal mengirim data OOS ke server.';
        } else {
          message = 'Tidak ada koneksi internet. Data disimpan secara lokal.';
          success = false; 
        }
      } else { 
        for (var oosItem in oosItemsToProcess) {
          oosItem.isSynced = 0;
          await _dbHelper.insertOOSItem(oosItem);
        }
        message = 'Data OOS berhasil disimpan secara lokal.';
        success = true;
      }
    } catch (e) {
      message = "Terjadi kesalahan: $e";
      print("Error during _sendData: $e");
      success = false;
      if (isOnline) {
        try {
          for (var oosItem in oosItemsToProcess) {
            oosItem.isSynced = 0;
            await _dbHelper.insertOOSItem(oosItem);
          }
          message += "\nData disimpan lokal karena error.";
        } catch (dbError) {
          print("Error saving to local DB after online error: $dbError");
        }
      }
    }

    if (mounted) Navigator.pop(context); 
    if (mounted) setState(() { _isLoading = false; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    
    if (success && mounted) {
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Out of Stock (OOS)'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: "Ketik nama atau kode produk...",
              onChanged: _onSearchChanged, // Gunakan _onSearchChanged dengan debouncer
              onScanPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur scan belum diimplementasi.')),
                );
              },
            ),
          ),
          if (_isSearching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(product.name ?? 'Nama Produk Tidak Tersedia'),
                      subtitle: Text('Kode: ${product.code ?? '-'}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle, color: AppColors.success, size: 30),
                        tooltip: 'Tambah ke OOS',
                        onPressed: () => _addProduct(product),
                      ),
                    ),
                  );
                },
              ),
            )
          else if (_searchController.text.trim().isNotEmpty && _searchResults.isEmpty && !_isSearching)
             const Expanded(child: Center(child: Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('Produk tidak ditemukan di database lokal.', style: TextStyle(fontSize: 16)),
             )))
          else
            Expanded(
              child: _selectedProducts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Silakan cari dan tambahkan produk yang stoknya habis (OOS) atau menipis.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                      itemCount: _selectedProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_selectedProducts[index], index);
                      },
                    ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showSendDialog,
        icon: const Icon(Icons.send, color: Colors.white),
        label: const Text("SIMPAN DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _selectedProducts.isEmpty || _isLoading ? Colors.grey : AppColors.primary,
      ),
    );
  }

  Widget _buildProductCard(OOSInputProduct oosInputProduct, int index) {
    // ... (Isi widget _buildProductCard sama seperti di respons sebelumnya, tidak ada perubahan di sini) ...
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    oosInputProduct.product.name?.toUpperCase() ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever_outlined, color: Colors.red[600], size: 26),
                  tooltip: 'Hapus Produk Ini',
                  onPressed: () {
                    setState(() {
                      _selectedProducts.removeAt(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const Divider(thickness: 0.8, height: 16),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Expanded(
                  flex: 5, 
                  child: TextFormField(
                    controller: oosInputProduct.quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity OOS',
                      hintText: oosInputProduct.isEmpty ? '0' : 'Jumlah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabled: !oosInputProduct.isEmpty,
                      filled: oosInputProduct.isEmpty,
                      fillColor: oosInputProduct.isEmpty ? Colors.grey[200] : Colors.transparent,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: oosInputProduct.isEmpty ? Colors.grey[700] : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4, 
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        oosInputProduct.isEmpty = !oosInputProduct.isEmpty;
                        if (oosInputProduct.isEmpty) {
                          oosInputProduct.quantityController.text = ''; 
                        }
                      });
                    },
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: oosInputProduct.isEmpty ? AppColors.error : AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          oosInputProduct.isEmpty ? Icons.do_not_disturb_on_outlined : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          oosInputProduct.isEmpty ? 'Kosong' : 'Tersedia',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: oosInputProduct.noteController,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Keterangan tambahan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}

// Model lokal untuk UI OutOfStockScreen yang memegang controller
class OOSInputProduct {
  final ProductSales product;
  final TextEditingController quantityController;
  final TextEditingController noteController;
  bool isEmpty;

  OOSInputProduct({
    required this.product,
    required this.quantityController,
    required this.noteController,
    this.isEmpty = true,
  });
}


// --- DEBOUNCER CLASS (Bisa diletakkan di file utilitas terpisah) ---
// Untuk mencegah pemanggilan search berlebihan saat pengguna mengetik cepat
class Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  NSTimer? _timer; // Menggunakan NSTimer dari dart:async agar bisa di-cancel

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = NSTimer(Duration(milliseconds: milliseconds), () {
      _action?.call();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

// Timer yang bisa di-cancel dari dart:async (pengganti Timer jika ada ambiguitas)
typedef NSTimer = Timer; // Alias untuk kejelasan, bisa langsung pakai Timer dari dart:async
// import 'dart:async'; // Pastikan import Timer sudah ada di atas file

// Contoh AppColors.dart (jika belum ada):
// import 'package:flutter/material.dart';
// class AppColors {
//   static const Color primaryColor = Colors.teal;
//   static const Color primaryTextColor = Colors.black87;
//   static const Color successColor = Colors.green;
//   static const Color dangerColor = Colors.redAccent;
// }
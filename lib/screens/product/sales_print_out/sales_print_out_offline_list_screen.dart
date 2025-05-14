import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/sales_print_out/api/sales_printout_api_service.dart';
import 'package:impact_app/screens/product/sales_print_out/model/sales_print_out_offline_models.dart';
import 'package:impact_app/themes/app_colors.dart'; // Sesuaikan path jika berbeda
import 'package:intl/intl.dart'; // Untuk format angka

class SalesPrintOutOfflineListScreen extends StatefulWidget {
  const SalesPrintOutOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<SalesPrintOutOfflineListScreen> createState() =>
      _SalesPrintOutOfflineListScreenState();
}

class _SalesPrintOutOfflineListScreenState
    extends State<SalesPrintOutOfflineListScreen> {
  final SalesByPrintOutApiService _apiService = SalesByPrintOutApiService();
  List<OfflineSalesGroup> _offlineSalesGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  // Formatter untuk angka
  final NumberFormat _currencyFormatter = NumberFormat.decimalPattern('id_ID');


  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _offlineSalesGroups = await _apiService.getOfflineSalesForDisplay();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memuat data offline: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    if (_offlineSalesGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')),
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kirim Data'),
          content: const Text('Anda yakin akan mengirim semua data offline ke server?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Kirim (Server)'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmSync != true) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    // Tampilkan dialog loading saat sinkronisasi
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Mengirim data..."),
          ],
        ),
      ),
    );

    try {
      bool success = await _apiService.syncOfflineSalesData();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sinkronisasi data berhasil.'),
              backgroundColor: Colors.green),
        );
        await _loadOfflineData(); // Muat ulang data setelah sinkronisasi
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Beberapa atau semua data gagal disinkronkan. Periksa log untuk detail.'),
              backgroundColor: Colors.orange),
        );
         await _loadOfflineData(); // Muat ulang data untuk melihat sisa data
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Tutup dialog loading
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat sinkronisasi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Widget _buildProductTable(List<OfflineSalesProductDetail> products) {
    return DataTable(
      columnSpacing: 12.0,
      horizontalMargin: 0,
      columns: const [
        DataColumn(label: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
      ],
      rows: products.map((product) {
        // Coba parse qty dan total ke double untuk format
        double qty = double.tryParse(product.qty) ?? 0;
        double total = double.tryParse(product.total) ?? 0;

        return DataRow(cells: [
          DataCell(
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35, // Atur lebar kolom produk
              child: Text(product.productName, overflow: TextOverflow.ellipsis),
            )
          ),
          DataCell(Text(_currencyFormatter.format(qty))),
          DataCell(Text(_currencyFormatter.format(total))),
        ]);
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Print Out Offline'),
        backgroundColor: AppColors.secondary, // Sesuaikan dengan AppColors Anda
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineSalesGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data sales offline.', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                        onPressed: _loadOfflineData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      )
                    ],
                  ))
              : RefreshIndicator(
                  onRefresh: _loadOfflineData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _offlineSalesGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineSalesGroups[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      group.outletName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                               Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    group.tgl,
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              _buildProductTable(group.products),
                              // Jika ingin menampilkan path gambar (opsional, untuk debug)
                              // ...group.products.map((p) => Text("Img: ${p.imagePath.split('/').last}")).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineSalesGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              icon: _isSyncing
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.send_to_mobile_outlined),
              label: Text(_isSyncing ? 'MENGIRIM...' : 'KIRIM DATA'),
              backgroundColor: _isSyncing ? Colors.grey : AppColors.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

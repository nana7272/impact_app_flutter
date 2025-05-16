// lib/screens/product/open_ending/open_ending_offline_list_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/open_ending/api/open_ending_api_service.dart';
import 'package:impact_app/screens/product/open_ending/models/open_ending_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart'; // Pastikan AppColors.primary, AppColors.secondary ada di sini
import 'package:intl/intl.dart'; // Untuk format angka dan tanggal

class OpenEndingOfflineListScreen extends StatefulWidget {
  const OpenEndingOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<OpenEndingOfflineListScreen> createState() =>
      _OpenEndingOfflineListScreenState();
}

class _OpenEndingOfflineListScreenState
    extends State<OpenEndingOfflineListScreen> {
  final OpenEndingApiService _apiService = OpenEndingApiService();
  List<OfflineOpenEndingGroup> _offlineOpenEndingGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

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
      _offlineOpenEndingGroups = await _apiService.getOfflineOpenEndingForDisplay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat data offline: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString; // Kembalikan string asli jika parsing gagal
    }
  }

  Future<void> _syncData() async {
    if (_offlineOpenEndingGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')),
      );
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kirim Data'),
          content: const Text('Anda yakin akan mengirim semua data Open Ending offline ke server?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Kirim (Server)'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), // Asumsi AppColors.primary ada
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmSync != true) return;

    setState(() { _isSyncing = true; });

    if (mounted) {
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
    }

    try {
      bool success = await _apiService.syncOfflineOpenEndingData();
      if (mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data berhasil.'), backgroundColor: Colors.green,));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data gagal disinkronkan.'), backgroundColor: Colors.orange,));
        await _loadOfflineData();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi: $e'), backgroundColor: Colors.red,));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  Widget _buildProductItem(OfflineOpenEndingProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), // Open
              1: FlexColumnWidth(1.5), // In
              2: FlexColumnWidth(1.5), // Ending
              3: FlexColumnWidth(2),   // Sell Out
            },
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            children: [
              TableRow( // Header Row
                decoration: BoxDecoration(color: Colors.grey[200]), // Pengganti AppColors.lightGrey
                children: const [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Open', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('In', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Ending', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Sell Out', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              TableRow( // Data Row
                children: [
                  Padding(padding: const EdgeInsets.all(6.0), child: Text(_numberFormatter.format(product.sf), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6.0), child: Text(_numberFormatter.format(product.si), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6.0), child: Text(_numberFormatter.format(product.sa), textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(6.0), child: Text(_numberFormatter.format(product.so), textAlign: TextAlign.center)),
                ],
              ),
            ],
          ),
          if (product.returnQty != null && product.returnQty! > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration( // Dihilangkan const di sini
                color: Colors.green[100]?.withOpacity(0.5) ?? Colors.green.withOpacity(0.5), // Pengganti AppColors.lightGreen
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[400] ?? Colors.green) // Pengganti AppColors.lightGreen untuk border
              ),
              child: Text(
                'Stock Return: ${_numberFormatter.format(product.returnQty)}'
                '${product.returnReason != null && product.returnReason!.isNotEmpty ? " (${product.returnReason})" : ""}',
                style: TextStyle(fontSize: 12, color: Colors.green[800]), // Pengganti AppColors.darkGreen
              ),
            ),
          ],
          if (product.expiredDate != null && product.expiredDate!.isNotEmpty) ...[
            const SizedBox(height: 6),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration( // Dihilangkan const di sini
                color: Colors.red[100]?.withOpacity(0.5) ?? Colors.red.withOpacity(0.5), // Pengganti AppColors.lightRed
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[400] ?? Colors.red) // Pengganti AppColors.lightRed untuk border
              ),
              child: Text(
                'Stock Expired: ${_formatDate(product.expiredDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.red[800]), // Pengganti AppColors.darkRed
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Ending Offline'),
        backgroundColor: AppColors.secondary, // Asumsi AppColors.secondary ada
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineOpenEndingGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data Open Ending offline.', style: TextStyle(fontSize: 16)),
                       const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                        onPressed: _loadOfflineData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), // Asumsi AppColors.primary ada
                      )
                    ],
                  ))
              : RefreshIndicator(
                  onRefresh: _loadOfflineData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 70.0), // Padding bawah untuk FAB
                    itemCount: _offlineOpenEndingGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineOpenEndingGroups[index];
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
                                  const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20), // Asumsi AppColors.primary ada
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      group.outletName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(group.tgl), // Format tanggal
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              ...group.products.map((product) => _buildProductItem(product)).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineOpenEndingGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              icon: _isSyncing
                  ? Container(
                      width: 24, height: 24, padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isSyncing ? 'MENGIRIM...' : 'KIRIM SEMUA'),
              backgroundColor: _isSyncing ? Colors.grey : AppColors.primary, // Asumsi AppColors.primary ada
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

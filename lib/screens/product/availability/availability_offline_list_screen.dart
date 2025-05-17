// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/availability/availability_offline_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/availability/api/availability_api_service.dart';
import 'package:impact_app/screens/product/availability/model/availability_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart';

class AvailabilityOfflineListScreen extends StatefulWidget {
  const AvailabilityOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<AvailabilityOfflineListScreen> createState() => _AvailabilityOfflineListScreenState();
}

class _AvailabilityOfflineListScreenState extends State<AvailabilityOfflineListScreen> {
  final AvailabilityApiService _apiService = AvailabilityApiService();
  List<OfflineAvailabilityHeader> _offlineHeaders = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'AvailabilityOfflineListScreen';

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      _offlineHeaders = await _apiService.getOfflineAvailabilityForDisplay();
      _logger.d(_tag, "Loaded ${_offlineHeaders.length} offline availability headers.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline availability data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error memuat data offline: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _formatSubmissionDate(String yyyyMmDd) {
    try {
      final DateTime dateTime = DateFormat('yyyy-MM-dd').parse(yyyyMmDd);
      return _dateFormatter.format(dateTime);
    } catch (e) {
      _logger.w(_tag, "Error formatting date: $yyyyMmDd, error: $e");
      return yyyyMmDd;
    }
  }

  Future<void> _syncData() async {
    if (_offlineHeaders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')));
      return;
    }

    bool hasInternet = await ConnectivityUtils.checkInternetConnection();
    if (!hasInternet) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada koneksi internet untuk sinkronisasi.')),
        );
        }
        return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Anda yakin akan mengirim semua data Availability offline ke server?'),
        actions: <Widget>[
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(
            child: const Text('Kirim (Server)'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmSync != true) return;
    if (!mounted) return;
    setState(() { _isSyncing = true; });

    showDialog(context: context, barrierDismissible: false, builder: (context) => 
      const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data...")]))
    );

    try {
      bool success = await _apiService.syncOfflineAvailabilityData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data Availability berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data Availability gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData(); 
      }
    } catch (e) {
      _logger.e(_tag, "Error during Availability sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showItemDetailsDialog(BuildContext context, OfflineAvailabilityHeader header) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Availability - ${header.outletName ?? header.idOutlet}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tanggal: ${_formatSubmissionDate(header.tglSubmission)}'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Foto Before", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        if (header.imageBeforePath != null && header.imageBeforePath!.isNotEmpty)
                          Image.file(File(header.imageBeforePath!), height: 80, width: 80, fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey, size: 40))
                        else
                          const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("Foto After", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        if (header.imageAfterPath != null && header.imageAfterPath!.isNotEmpty)
                          Image.file(File(header.imageAfterPath!), height: 80, width: 80, fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey, size: 40))
                        else
                          const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("Item Produk:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                if (header.items.isEmpty)
                  const Text("Tidak ada item produk.")
                else
                  ...header.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName ?? item.idProduct, style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("  Gudang: ${_numberFormatter.format(item.stockGudang)}, Display: ${_numberFormatter.format(item.stockDisplay)}, Total: ${_numberFormatter.format(item.totalStock)}"),
                      ],
                    ),
                  )).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Oke'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Availability Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineHeaders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data Availability offline.', style: TextStyle(fontSize: 16)),
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
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), 
                    itemCount: _offlineHeaders.length,
                    itemBuilder: (context, index) {
                      final header = _offlineHeaders[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (header.imageBeforePath != null && header.imageBeforePath!.isNotEmpty)
                                Image.file(File(header.imageBeforePath!), width: 40, height: 20, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.broken_image, size: 20))
                              else Icon(Icons.image_not_supported, size: 20),
                              if (header.imageAfterPath != null && header.imageAfterPath!.isNotEmpty)
                                Image.file(File(header.imageAfterPath!), width: 40, height: 20, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.broken_image, size: 20))
                              else Icon(Icons.image_not_supported, size: 20),
                            ],
                          ),
                          title: Text(header.outletName ?? header.idOutlet, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Tanggal: ${_formatSubmissionDate(header.tglSubmission)}'),
                              Text('Jumlah Item: ${header.items.length}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showItemDetailsDialog(context, header),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineHeaders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              heroTag: 'availability_offline_fab',
              icon: _isSyncing
                  ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isSyncing ? 'MENGIRIM...' : 'KIRIM SEMUA DATA'),
              backgroundColor: _isSyncing ? Colors.grey : AppColors.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

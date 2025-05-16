import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/oos/api/oos_api_service.dart';
import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';
import 'package:impact_app/screens/product/oos/model/oos_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';

class OosOfflineListScreen extends StatefulWidget {
  const OosOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<OosOfflineListScreen> createState() => _OosOfflineListScreenState();
}

class _OosOfflineListScreenState extends State<OosOfflineListScreen> {
  final OOSApiService _apiService = OOSApiService();
  List<OfflineOOSGroup> _offlineOOSGroups = [];
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
      _offlineOOSGroups = await _apiService.getOfflineOOSForDisplay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat data OOS offline: $e')),
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
      return dateString;
    }
  }

  Future<void> _syncData() async {
    if (_offlineOOSGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data OOS untuk disinkronkan.')),
      );
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kirim Data OOS'),
          content: const Text('Anda yakin akan mengirim semua data OOS offline ke server?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Kirim (Server)'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
              Text("Mengirim data OOS..."),
            ],
          ),
        ),
      );
    }

    try {
      bool success = await _apiService.syncOfflineOOSData();
      if (mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data OOS berhasil.'), backgroundColor: Colors.green,));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data OOS gagal disinkronkan.'), backgroundColor: Colors.orange,));
        await _loadOfflineData(); // Muat ulang untuk melihat sisa data jika ada
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi OOS: $e'), backgroundColor: Colors.red,));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  Widget _buildOOSItemDetail(OOSItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tipe: ${item.type}', style: const TextStyle(fontSize: 13)),
              Text('Qty: ${_numberFormatter.format(item.quantity)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          if (item.ket != null && item.ket!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Ket: ${item.ket}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 2),
          Text('Status Stok: ${item.isEmpty ? "Kosong" : "Ada"}', style: TextStyle(fontSize: 12, color: item.isEmpty ? AppColors.error : AppColors.success)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OOS Data Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineOOSGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data OOS offline.', style: TextStyle(fontSize: 16)),
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
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 70.0),
                    itemCount: _offlineOOSGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineOOSGroups[index];
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
                                  const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
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
                                    _formatDate(group.tgl),
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              ...group.items.map((item) => _buildOOSItemDetail(item)).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineOOSGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              icon: _isSyncing
                  ? Container(
                      width: 24, height: 24, padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isSyncing ? 'MENGIRIM...' : 'KIRIM SEMUA'),
              backgroundColor: _isSyncing ? Colors.grey : AppColors.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// lib/screens/product/planogram/planogram_offline_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/planogram/api/planogram_api_service.dart';
import 'package:impact_app/screens/product/planogram/model/planogram_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart';

class PlanogramOfflineListScreen extends StatefulWidget {
  const PlanogramOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<PlanogramOfflineListScreen> createState() => _PlanogramOfflineListScreenState();
}

class _PlanogramOfflineListScreenState extends State<PlanogramOfflineListScreen> {
  final PlanogramApiService _apiService = PlanogramApiService();
  List<OfflinePlanogramGroup> _offlineGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'PlanogramOfflineListScreen';

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      _offlineGroups = await _apiService.getOfflinePlanogramEntriesForDisplay();
      _logger.d(_tag, "Loaded ${_offlineGroups.length} offline planogram groups.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline planogram data: $e");
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
      return 'Tgl Error';
    }
  }

  Future<void> _syncData() async {
    if (_offlineGroups.isEmpty) {
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
        content: const Text('Anda yakin akan mengirim semua data Planogram offline ke server?'),
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
      bool success = await _apiService.syncOfflinePlanogramEntries();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data Planogram berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data Planogram gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData(); 
      }
    } catch (e) {
      _logger.e(_tag, "Error during Planogram sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi Planogram: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showItemDetailsDialog(BuildContext context, OfflinePlanogramItemDetail item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Planogram (${item.displayType})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tipe Display: ${item.displayType ?? "-"}'),
                const SizedBox(height: 8),
                Text('Issue Display: ${item.displayIssue ?? "-"}'),
                const SizedBox(height: 8),
                Text('Ket. Before: ${item.ketBefore ?? "-"}'),
                if (item.imageBeforePath != null && item.imageBeforePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: Image.file(File(item.imageBeforePath!), height: 100, fit: BoxFit.contain,
                      errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey))),
                  ),
                const SizedBox(height: 8),
                Text('Ket. After: ${item.ketAfter ?? "-"}'),
                 if (item.imageAfterPath != null && item.imageAfterPath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: Image.file(File(item.imageAfterPath!), height: 100, fit: BoxFit.contain,
                      errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey))),
                  ),
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
        title: const Text('Data Planogram Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.view_quilt_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data Planogram offline.', style: TextStyle(fontSize: 16)),
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
                    itemCount: _offlineGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineGroups[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.outletName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatSubmissionDate(group.tglSubmission),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text("Jumlah Item: ${group.items.length}", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 8),
                              if (group.items.isNotEmpty)
                                SizedBox(
                                  height: 100, 
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: group.items.length,
                                    itemBuilder: (ctx, itemIndex) {
                                      final item = group.items[itemIndex];
                                      return GestureDetector(
                                        onTap: () => _showItemDetailsDialog(context, item),
                                        child: Tooltip(
                                          message: "Tipe: ${item.displayType}\nIssue: ${item.displayIssue}",
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      if (item.imageBeforePath != null && item.imageBeforePath!.isNotEmpty)
                                                        AspectRatio(
                                                          aspectRatio: 1,
                                                          child: Container(
                                                            margin: EdgeInsets.only(right: 4),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8.0),
                                                              border: Border.all(color: Colors.blue.shade200)
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(7.0),
                                                              child: Image.file(File(item.imageBeforePath!), fit: BoxFit.cover,
                                                                errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 30))),
                                                            ),
                                                          ),
                                                        ),
                                                      if (item.imageAfterPath != null && item.imageAfterPath!.isNotEmpty)
                                                        AspectRatio(
                                                          aspectRatio: 1,
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8.0),
                                                              border: Border.all(color: Colors.green.shade200)
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(7.0),
                                                              child: Image.file(File(item.imageAfterPath!), fit: BoxFit.cover,
                                                                errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 30))),
                                                            ),
                                                          ),
                                                        ),
                                                      if ((item.imageBeforePath == null || item.imageBeforePath!.isEmpty) && (item.imageAfterPath == null || item.imageAfterPath!.isEmpty))
                                                         AspectRatio(
                                                          aspectRatio: 1,
                                                          child: Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30)),
                                                         )
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  item.displayType ?? 'Planogram',
                                                  style: TextStyle(fontSize: 10, color: Colors.black54, overflow: TextOverflow.ellipsis),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text("Tidak ada item dalam grup ini.", style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              heroTag: 'planogram_offline_list_fab',
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

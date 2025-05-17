// lib/screens/product/posm/posm_offline_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/posm/api/posm_api_service.dart';
import 'package:impact_app/screens/product/posm/model/posm_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:impact_app/utils/logger.dart'; // Import Logger

class PosmOfflineListScreen extends StatefulWidget {
  const PosmOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<PosmOfflineListScreen> createState() => _PosmOfflineListScreenState();
}

class _PosmOfflineListScreenState extends State<PosmOfflineListScreen> {
  final PosmApiService _apiService = PosmApiService();
  List<OfflinePosmGroup> _offlinePosmGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger(); // Tambahkan Logger
  final String _tag = 'PosmOfflineListScreen'; // Tag untuk logging

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      _offlinePosmGroups = await _apiService.getOfflinePosmForDisplay();
      _logger.d(_tag, "Loaded ${_offlinePosmGroups.length} offline POSM groups.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline POSM data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error memuat data offline: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _formatTimestampDate(String isoTimestamp) {
    try {
      final DateTime dateTime = DateTime.parse(isoTimestamp);
      return _dateFormatter.format(dateTime);
    } catch (e) {
      _logger.w(_tag, "Error formatting date from timestamp: $isoTimestamp, error: $e");
      return 'Tgl Error';
    }
  }

  String _formatTimestampTime(String isoTimestamp) {
    try {
      final DateTime dateTime = DateTime.parse(isoTimestamp);
      return _timeFormatter.format(dateTime);
    } catch (e) {
      _logger.w(_tag, "Error formatting time from timestamp: $isoTimestamp, error: $e");
      return 'Waktu Error';
    }
  }

  Future<void> _syncData() async {
    if (_offlinePosmGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')));
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kirim Data'),
        content: const Text('Anda yakin akan mengirim semua data POSM offline ke server?'),
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
      bool success = await _apiService.syncOfflinePosmData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data POSM berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data POSM gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData(); // Muat ulang untuk melihat sisa data jika ada
      }
    } catch (e) {
      _logger.e(_tag, "Error during POSM sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi POSM: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showPosmItemDetailsDialog(BuildContext context, OfflinePosmItemDetail item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.type ?? 'Detail POSM'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (item.imagePath != null && item.imagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Center(
                      child: Image.file(
                        File(item.imagePath!),
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                Text('Tipe: ${item.type ?? "-"}'),
                const SizedBox(height: 8),
                Text('Status: ${item.posmStatus ?? "-"}'),
                const SizedBox(height: 8),
                Text('Terpasang: ${item.quantity?.toString() ?? "-"}'),
                const SizedBox(height: 8),
                Text('Keterangan: ${item.ket ?? "-"}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Oke'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: const Text('Data POSM Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlinePosmGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data POSM offline.', style: TextStyle(fontSize: 16)),
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
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // Padding bawah untuk FAB
                    itemCount: _offlinePosmGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlinePosmGroups[index];
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
                                    _formatTimestampDate(group.timestamp),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestampTime(group.timestamp),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              if (group.items.isNotEmpty)
                                SizedBox(
                                  height: 100, // Tinggi untuk preview gambar
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: group.items.length,
                                    itemBuilder: (ctx, itemIndex) {
                                      final item = group.items[itemIndex];
                                      if (item.imagePath == null || item.imagePath!.isEmpty) {
                                        return const SizedBox.shrink(); // Jangan tampilkan jika tidak ada path gambar
                                      }
                                      return GestureDetector(
                                        onTap: () => _showPosmItemDetailsDialog(context, item),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.file(
                                              File(item.imagePath!),
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 100, height: 100, color: Colors.grey[200],
                                                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text("Tidak ada item POSM dalam grup ini.", style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlinePosmGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              heroTag: 'posm_offline_list_fab', // Unique heroTag
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

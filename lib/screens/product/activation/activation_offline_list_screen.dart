// File BARU: /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/activation_offline_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/models/activation_model.dart';
import 'package:impact_app/screens/product/activation/api/activation_api_service.dart';
import 'package:impact_app/screens/product/activation/model/activation_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:impact_app/utils/logger.dart';

class ActivationOfflineListScreen extends StatefulWidget {
  const ActivationOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<ActivationOfflineListScreen> createState() => _ActivationOfflineListScreenState();
}

class _ActivationOfflineListScreenState extends State<ActivationOfflineListScreen> {
  final ActivationApiService _apiService = ActivationApiService();
  List<OfflineActivationGroup> _offlineActivationGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'ActivationOfflineListScreen';

  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      _offlineActivationGroups = await _apiService.getOfflineActivationsForDisplay();
      _logger.d(_tag, "Loaded ${_offlineActivationGroups.length} offline activation groups.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline activation data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error memuat data offline: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return _dateFormatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _syncData() async {
    if (_offlineActivationGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')));
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kirim Data Aktivasi'),
        content: const Text('Anda yakin akan mengirim semua data aktivasi offline ke server?'),
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
      const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data aktivasi...")]))
    );

    try {
      bool success = await _apiService.syncOfflineActivationData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data aktivasi berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data aktivasi gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData();
      }
    } catch (e) {
      _logger.e(_tag, "Error during activation sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi aktivasi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showActivationItemDetailsDialog(BuildContext context, ActivationEntryModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.program),
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
                Text('Program: ${item.program}'),
                const SizedBox(height: 8),
                Text('Periode: ${item.rangePeriode}'),
                const SizedBox(height: 8),
                Text('Keterangan: ${item.keterangan ?? "-"}'),
                const SizedBox(height: 8),
                Text('Outlet: ${item.outletName ?? item.idOutlet}'),
                const SizedBox(height: 8),
                Text('Tanggal Input: ${_formatDate(item.tgl)}'),
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
        title: const Text('Data Aktivasi Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineActivationGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data aktivasi offline.', style: TextStyle(fontSize: 16)),
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
                    itemCount: _offlineActivationGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineActivationGroups[index];
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
                                    _formatDate(group.tgl),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              if (group.items.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: group.items.length,
                                  separatorBuilder: (context, itemIndex) => const Divider(thickness: 0.5, height: 10),
                                  itemBuilder: (ctx, itemIndex) {
                                    final item = group.items[itemIndex];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: (item.imagePath != null && item.imagePath!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4.0),
                                              child: Image.file(
                                                File(item.imagePath!),
                                                width: 50, height: 50, fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 30),
                                              ),
                                            )
                                          : const Icon(Icons.campaign, size: 30, color: Colors.grey),
                                      title: Text(item.program, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: Text(item.rangePeriode),
                                      onTap: () => _showActivationItemDetailsDialog(context, item),
                                    );
                                  },
                                )
                              else
                                const Text("Tidak ada item aktivasi dalam grup ini.", style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineActivationGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
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

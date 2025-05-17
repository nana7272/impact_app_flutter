// lib/screens/survey/survey_offline_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/survey/api/survey_api_service.dart';
import 'package:impact_app/screens/product/survey/model/offline_survey_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart';

class SurveyOfflineListScreen extends StatefulWidget {
  const SurveyOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<SurveyOfflineListScreen> createState() => _SurveyOfflineListScreenState();
}

class _SurveyOfflineListScreenState extends State<SurveyOfflineListScreen> {
  final SurveyApiService _apiService = SurveyApiService();
  List<OfflineSurveyGroup> _offlineSurveyGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'SurveyOfflineListScreen';

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      _offlineSurveyGroups = await _apiService.getOfflineSurveyForDisplay();
      _logger.d(_tag, "Loaded ${_offlineSurveyGroups.length} offline survey groups.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline survey data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error memuat data survey offline: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _formatTimestamp(String isoTimestamp) {
    try {
      final DateTime dateTime = DateTime.parse(isoTimestamp);
      return _dateFormatter.format(dateTime.toLocal());
    } catch (e) {
      _logger.w(_tag, "Error formatting timestamp: $isoTimestamp, error: $e");
      return 'Tgl Error';
    }
  }

  Future<void> _syncData() async {
    if (_offlineSurveyGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data survey untuk disinkronkan.')));
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kirim Data Survey'),
        content: const Text('Anda yakin akan mengirim semua data survey offline ke server?'),
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
      const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data survey...")]))
    );

    try {
      bool success = await _apiService.syncOfflineSurveyData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data survey berhasil.'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data survey gagal disinkronkan. Data yang gagal tetap tersimpan offline.'), backgroundColor: Colors.orange));
      }
      await _loadOfflineData(); // Muat ulang untuk melihat sisa data jika ada
    } catch (e) {
      _logger.e(_tag, "Error during survey sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi survey: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showSurveyGroupDetailsDialog(BuildContext context, OfflineSurveyGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Survey: ${group.outletName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Outlet: ${group.outletName}', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Waktu: ${_formatTimestamp(group.tglSubmission)}'),
                Text('ID Pengguna: ${group.idUser}'),
                Text('ID Principle: ${group.idPrinciple}'),
                Divider(height: 20),
                Text('Jawaban:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (group.items.isEmpty) Text("Tidak ada item jawaban."),
                ...group.items.map((item) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.pertanyaan, style: TextStyle(fontStyle: FontStyle.italic)),
                          SizedBox(height: 4),
                          Text('Tipe: ${item.typeJawaban}'),
                          if (item.idJawabanKey != null) Text('ID Kunci: ${item.idJawabanKey}'),
                          if (item.jawabanText != null) Text('Jawaban: ${item.jawabanText}'),
                          if (item.valueLainnya != null) Text('Lainnya: ${item.valueLainnya}'),
                          if (item.imagePath != null && item.imagePath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.file(
                                File(item.imagePath!),
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, st) => Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup'),
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
        title: const Text('Data Survey Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineSurveyGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data survey offline.', style: TextStyle(fontSize: 16)),
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
                    itemCount: _offlineSurveyGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlineSurveyGroups[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell( // Make card tappable
                          onTap: () => _showSurveyGroupDetailsDialog(context, group),
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
                                      _formatTimestamp(group.tglSubmission),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.items.length} Pertanyaan Dijawab',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                // You can add a preview of some answers or images here if needed
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineSurveyGroups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              heroTag: 'survey_offline_list_fab', 
              icon: _isSyncing
                  ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isSyncing ? 'MENGIRIM...' : 'KIRIM SEMUA SURVEY'),
              backgroundColor: _isSyncing ? Colors.grey : AppColors.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

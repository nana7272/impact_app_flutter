// /Users/nananurwanda/Documents/SOURCE CODE RAMEZA/rameza_new_templete_flutter/lib/screens/product/sampling_konsument/sampling_konsumen_offline_list_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/product/sampling_konsument/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/screens/product/sampling_konsument/model/sampling_konsumen_offline_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:intl/intl.dart';

class SamplingKonsumenOfflineListScreen extends StatefulWidget {
  const SamplingKonsumenOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<SamplingKonsumenOfflineListScreen> createState() => _SamplingKonsumenOfflineListScreenState();
}

class _SamplingKonsumenOfflineListScreenState extends State<SamplingKonsumenOfflineListScreen> {
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  List<OfflineSamplingKonsumenItem> _offlineItems = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'SamplingKonsumenOfflineListScreen';

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
      _offlineItems = await _apiService.getOfflineSamplingKonsumenForDisplay();
      _logger.d(_tag, "Loaded ${_offlineItems.length} offline sampling konsumen items.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline sampling konsumen data: $e");
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
      return yyyyMmDd; // Return original if parsing fails
    }
  }

  Future<void> _syncData() async {
    if (_offlineItems.isEmpty) {
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
        content: const Text('Anda yakin akan mengirim semua data Sampling Konsumen offline ke server?'),
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
      bool success = await _apiService.syncOfflineSamplingKonsumenData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data Sampling Konsumen berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData(); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data Sampling Konsumen gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData(); 
      }
    } catch (e) {
      _logger.e(_tag, "Error during Sampling Konsumen sync process: $e");
      if(mounted) Navigator.of(context).pop(); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _showItemDetailsDialog(BuildContext context, OfflineSamplingKonsumenItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Sampling: ${item.namaKonsumen}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Outlet: ${item.outletName ?? item.idOutlet}'),
                const SizedBox(height: 8),
                Text('Tanggal: ${_formatSubmissionDate(item.tglSubmission)}'),
                const SizedBox(height: 8),
                Text('No HP: ${item.noHpKonsumen}'),
                const SizedBox(height: 8),
                Text('Umur: ${item.umurKonsumen} tahun'),
                const SizedBox(height: 8),
                Text('Email: ${item.emailKonsumen ?? "-"}'),
                const SizedBox(height: 8),
                Text('Alamat: ${item.alamatKonsumen}'),
                const SizedBox(height: 8),
                Text('Produk Dibeli: ${item.namaProductDibeli ?? item.idProductDibeli}'),
                const SizedBox(height: 8),
                Text('Kuantitas: ${_numberFormatter.format(item.kuantitas)}'),
                const SizedBox(height: 8),
                Text('Produk Sebelumnya: ${item.namaProductSebelumnya ?? item.idProductSebelumnya ?? "-"}'),
                const SizedBox(height: 8),
                Text('Keterangan: ${item.keterangan ?? "-"}'),
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
        title: const Text('Data Sampling Konsumen Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data Sampling Konsumen offline.', style: TextStyle(fontSize: 16)),
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
                    itemCount: _offlineItems.length,
                    itemBuilder: (context, index) {
                      final item = _offlineItems[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          title: Text(item.namaKonsumen, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Outlet: ${item.outletName ?? item.idOutlet}'),
                              Text('Produk Dibeli: ${item.namaProductDibeli ?? item.idProductDibeli} (Qty: ${_numberFormatter.format(item.kuantitas)})'),
                              Text('Tanggal: ${_formatSubmissionDate(item.tglSubmission)}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showItemDetailsDialog(context, item),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlineItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncData,
              heroTag: 'sampling_konsumen_offline_fab',
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

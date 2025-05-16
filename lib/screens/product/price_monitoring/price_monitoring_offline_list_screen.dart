import 'package:flutter/material.dart';
import 'package:impact_app/models/price_monitoring_model.dart';
import 'package:impact_app/screens/product/price_monitoring/api/price_monitoring_api_service.dart';
import 'package:impact_app/screens/product/price_monitoring/model/price_monitoring_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:impact_app/utils/logger.dart';

class PriceMonitoringOfflineListScreen extends StatefulWidget {
  const PriceMonitoringOfflineListScreen({Key? key}) : super(key: key);

  @override
  State<PriceMonitoringOfflineListScreen> createState() => _PriceMonitoringOfflineListScreenState();
}

class _PriceMonitoringOfflineListScreenState extends State<PriceMonitoringOfflineListScreen> {
  final PriceMonitoringApiService _apiService = PriceMonitoringApiService();
  List<OfflinePriceMonitoringGroup> _offlinePriceMonitoringGroups = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final Logger _logger = Logger();
  final String _tag = 'PriceMonitoringOfflineListScreen';

  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');
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
      _offlinePriceMonitoringGroups = await _apiService.getOfflinePriceMonitoringForDisplay();
      _logger.d(_tag, "Loaded ${_offlinePriceMonitoringGroups.length} offline price monitoring groups.");
    } catch (e) {
      _logger.e(_tag, "Error loading offline price monitoring data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error memuat data offline: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return _dateFormatter.format(dateTime);
    } catch (e) {
      _logger.w(_tag, "Error formatting date from string: $dateString, error: $e");
      return dateString;
    }
  }

  String _formatPrice(String? priceString) {
     if (priceString == null || priceString.isEmpty) return '0';
     try {
       final int price = int.parse(priceString); // Assuming integer prices
       return _numberFormatter.format(price);
     } catch (e) {
       _logger.w(_tag, "Error formatting price from string: $priceString, error: $e");
       return priceString; // Return original string if parsing fails
     }
  }


  Future<void> _syncData() async {
    if (_offlinePriceMonitoringGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk disinkronkan.')));
      return;
    }

    bool? confirmSync = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kirim Data Price Monitoring'),
        content: const Text('Anda yakin akan mengirim semua data Price Monitoring offline ke server?'),
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
      const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Mengirim data Price Monitoring...")]))
    );

    try {
      bool success = await _apiService.syncOfflinePriceMonitoringData();
      if(mounted) Navigator.of(context).pop(); // Tutup dialog loading

      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data Price Monitoring berhasil.'), backgroundColor: Colors.green));
        await _loadOfflineData();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beberapa atau semua data Price Monitoring gagal disinkronkan.'), backgroundColor: Colors.orange));
        await _loadOfflineData(); // Muat ulang untuk melihat sisa data jika ada
      }
    } catch (e) {
      _logger.e(_tag, "Error during Price Monitoring sync process: $e");
      if(mounted) Navigator.of(context).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saat sinkronisasi Price Monitoring: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  Widget _buildPriceItemDetail(PriceMonitoringEntryModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName ?? 'Unknown Product',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Normal: Rp ${_formatPrice(item.hargaNormal)}', style: const TextStyle(fontSize: 13)),
              Text('Promo: Rp ${_formatPrice(item.hargaDiskon)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          if (item.ket != null && item.ket!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Ket: ${item.ket}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Price Monitoring Offline'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlinePriceMonitoringGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Tidak ada data Price Monitoring offline.', style: TextStyle(fontSize: 16)),
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
                    itemCount: _offlinePriceMonitoringGroups.length,
                    itemBuilder: (context, index) {
                      final group = _offlinePriceMonitoringGroups[index];
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
                                    return _buildPriceItemDetail(item); // Display item details
                                  },
                                )
                              else
                                const Text("Tidak ada item price monitoring dalam grup ini.", style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _offlinePriceMonitoringGroups.isNotEmpty
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
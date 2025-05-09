// lib/screens/sampling_konsumen_list_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/api/sampling_konsumen_api_service.dart';
import 'package:impact_app/models/sampling_konsumen_model.dart';
import 'package:impact_app/screens/sampling_konsumen_screen.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:intl/intl.dart';

class SamplingKonsumenListScreen extends StatefulWidget {
  final String storeId;
  final String visitId;
  
  const SamplingKonsumenListScreen({
    Key? key, 
    required this.storeId, 
    required this.visitId,
  }) : super(key: key);

  @override
  State<SamplingKonsumenListScreen> createState() => _SamplingKonsumenListScreenState();
}

class _SamplingKonsumenListScreenState extends State<SamplingKonsumenListScreen> {
  final SamplingKonsumenApiService _apiService = SamplingKonsumenApiService();
  bool _isLoading = true;
  bool _isSyncing = false;
  List<SamplingKonsumen> _samplingList = [];
  List<SamplingKonsumen> _pendingSamplingList = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get online data
      final onlineData = await _apiService.getSamplingKonsumenHistory();
      
      // Get pending data
      final pendingData = await _apiService.getPendingSamplingKonsumen();
      
      setState(() {
        _samplingList = onlineData;
        _pendingSamplingList = pendingData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }
  
  Future<void> _syncPendingData() async {
    // Check if there's any pending data
    if (_pendingSamplingList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data yang perlu disinkronkan')),
      );
      return;
    }
    
    // Check internet connection
    bool isConnected = await ConnectivityUtils.checkInternetConnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada koneksi internet')),
      );
      return;
    }
    
    setState(() {
      _isSyncing = true;
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Sinkronisasi Data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
    
    try {
      bool success = await _apiService.syncPendingSamplingKonsumen();
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disinkronkan')),
        );
        // Reload data
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beberapa data gagal disinkronkan')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sinkronisasi data: $e')),
      );
    }
    
    setState(() {
      _isSyncing = false;
    });
  }
  
  void _navigateToAddSampling() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SamplingKonsumenScreen(
          storeId: widget.storeId,
          visitId: widget.visitId,
        ),
      ),
    ).then((_) {
      // Reload data when returning from the add screen
      _loadData();
    });
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Sampling Konsumen'),
        backgroundColor: Colors.grey[700],
        actions: [
          if (_pendingSamplingList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncPendingData,
              tooltip: 'Sinkronkan Data Pending',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSampling,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_samplingList.isEmpty && _pendingSamplingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data sampling konsumen',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddSampling,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Sampling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Create combined list
    final List<SamplingKonsumen> combinedList = [
      ..._pendingSamplingList,
      ..._samplingList,
    ];
    
    return Column(
      children: [
        if (_pendingSamplingList.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ada ${_pendingSamplingList.length} data yang belum tersinkronisasi',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSyncing ? null : _syncPendingData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sync'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: combinedList.length,
            itemBuilder: (context, index) {
              final item = combinedList[index];
              final isPending = _pendingSamplingList.contains(item);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    item.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No. HP: ${item.noHp}'),
                      Text('Email: ${item.email}'),
                      Text('Kuantitas: ${item.kuantitas}'),
                      Text('Tanggal: ${_formatDate(item.createdAt)}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: isPending
                      ? Chip(
                          label: const Text('Pending'),
                          backgroundColor: AppColors.warning.withOpacity(0.2),
                          labelStyle: const TextStyle(color: AppColors.warning),
                        )
                      : const Icon(Icons.check_circle, color: AppColors.success),
                  onTap: () {
                    // Show detail if needed
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(item.nama),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _detailRow('No. HP', item.noHp),
                              _detailRow('Umur', item.umur),
                              _detailRow('Alamat', item.alamat),
                              _detailRow('Email', item.email),
                              _detailRow('Produk Sebelumnya', item.produkSebelumnya ?? 'N/A'),
                              _detailRow('Produk Yang Dibeli', item.produkYangDibeli ?? 'N/A'),
                              _detailRow('Kuantitas', item.kuantitas.toString()),
                              _detailRow('Keterangan', item.keterangan),
                              _detailRow('Tanggal', _formatDate(item.createdAt)),
                              _detailRow('Status', isPending ? 'Pending' : 'Tersinkronisasi'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
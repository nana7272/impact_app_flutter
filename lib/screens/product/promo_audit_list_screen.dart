// lib/screens/promo_audit_list_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/api/api_services.dart';
import 'package:impact_app/api/promo_audit_api_service.dart';
import 'package:impact_app/models/promo_audit_model.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/screens/product/promo_audit_screen.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:intl/intl.dart';

class PromoAuditListScreen extends StatefulWidget {
  const PromoAuditListScreen({Key? key}) : super(key: key);

  @override
  State<PromoAuditListScreen> createState() => _PromoAuditListScreenState();
}

class _PromoAuditListScreenState extends State<PromoAuditListScreen> {
  final PromoAuditApiService _apiService = PromoAuditApiService();
  final ApiService _storeApiService = ApiService();
  
  bool _isLoading = true;
  bool _isSyncing = false;
  List<PromoAudit> _promoAuditList = [];
  List<PromoAudit> _pendingPromoAuditList = [];
  List<Store> _storeList = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // Load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load stores first
      final stores = await _storeApiService.getStores(0, 0);
      
      // Load online data
      final onlineData = await _apiService.getPromoAuditHistory();
      
      // Load pending data
      final pendingData = await _apiService.getPendingPromoAudits();
      
      setState(() {
        _storeList = stores;
        _promoAuditList = onlineData;
        _pendingPromoAuditList = pendingData;
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
  
  // Sync pending data
  Future<void> _syncPendingData() async {
    // Check if there's any pending data
    if (_pendingPromoAuditList.isEmpty) {
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
      bool success = await _apiService.syncPendingPromoAudits();
      
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
  
  // Get store name by ID
  String _getStoreName(String storeId) {
    final store = _storeList.firstWhere(
      (store) => store.idOutlet == storeId,
      orElse: () => Store(nama: 'Unknown Store'),
    );
    
    return store.nama ?? 'Unknown Store';
  }
  
  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  // Navigate to add/edit promo audit
  void _navigateToPromoAudit(Store store, {String? visitId}) {
    // Generate visit ID if not provided
    final String finalVisitId = visitId ?? 'visit_${DateTime.now().millisecondsSinceEpoch}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoAuditScreen(
          storeId: store.idOutlet!,
          visitId: finalVisitId,
          store: store,
        ),
      ),
    ).then((_) {
      // Reload data when returning from the add/edit screen
      _loadData();
    });
  }
  
  // Show store selection dialog
  void _showStoreSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Toko'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _storeList.length,
            itemBuilder: (context, index) {
              final store = _storeList[index];
              return ListTile(
                title: Text(store.nama ?? 'Unnamed Store'),
                subtitle: Text(store.alamat ?? 'No address'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPromoAudit(store);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Audit'),
        backgroundColor: Colors.grey[700],
        actions: [
          if (_pendingPromoAuditList.isNotEmpty)
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
        onPressed: _showStoreSelectionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_storeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada toko tersedia',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    if (_promoAuditList.isEmpty && _pendingPromoAuditList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data promo audit',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showStoreSelectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Promo Audit'),
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
    final List<PromoAudit> combinedList = [
      ..._pendingPromoAuditList,
      ..._promoAuditList,
    ];
    
    return Column(
      children: [
        if (_pendingPromoAuditList.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ada ${_pendingPromoAuditList.length} data yang belum tersinkronisasi',
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
              final isPending = _pendingPromoAuditList.contains(item);
              final storeName = _getStoreName(item.storeId ?? '');
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${item.statusPromotion ? 'Berjalan' : 'Tidak Berjalan'}'),
                      Text('Extra Display: ${item.extraDisplay ? 'Ada' : 'Tidak Ada'}'),
                      Text('POP Promo: ${item.popPromo ? 'Terpasang' : 'Tidak Terpasang'}'),
                      Text('Harga Promo: ${item.hargaPromo ? 'Sesuai' : 'Tidak Sesuai'}'),
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
                    // Get store and navigate to detail page
                    final store = _storeList.firstWhere(
                      (store) => store.idOutlet == item.storeId,
                      orElse: () => Store(idOutlet: item.storeId, nama: 'Unknown Store'),
                    );
                    
                    _navigateToPromoAudit(store, visitId: item.visitId);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
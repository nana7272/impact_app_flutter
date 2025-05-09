import 'dart:async';
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activation_screen.dart';
import 'package:impact_app/screens/out_of_stock_screen.dart';
import 'package:impact_app/screens/posm_screen.dart';
import 'package:impact_app/screens/price_monitoring_screen.dart';
import 'package:impact_app/screens/promo_audit_list_screen.dart';
import 'package:impact_app/screens/sampling_konsumen_list_screen.dart';
import 'package:impact_app/screens/sampling_konsumen_screen.dart';
import '../api/api_services.dart';
import '../models/store_model.dart';
import '../models/sales_print_out_model.dart';
import '../screens/sales_print_out_screen.dart';
import '../screens/open_ending_screen.dart'; // Added import for OpenEndingScreen
import '../utils/session_manager.dart';
import '../utils/logger.dart';
import '../themes/app_colors.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();
  final String _tag = 'SalesScreen';
  
  Store? _currentStore;
  String? _currentVisitId;
  DateTime? _checkInTime;
  String _elapsedTime = "00:00:00";
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCurrentVisit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentVisit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch current visit data from API
      final currentVisitResponse = await _apiService.getCurrentVisit();
      
      if (currentVisitResponse != null && 
          currentVisitResponse['data'] != null &&
          currentVisitResponse['data']['store_id'] != null) {
        
        final storeId = currentVisitResponse['data']['store_id'];
        final visitId = currentVisitResponse['data']['id'];
        
        // Parse check-in time
        if (currentVisitResponse['data']['check_in_time'] != null) {
          _checkInTime = DateTime.parse(currentVisitResponse['data']['check_in_time']);
          // Start timer
          _startTimer();
        }
        
        // Fetch store details
        final storeResponse = await _apiService.getStoreById(storeId);
        
        setState(() {
          _currentVisitId = visitId;
          _currentStore = Store.fromJson(storeResponse['data']);
        });
        
        _logger.d(_tag, 'Current visit loaded: Store ${_currentStore?.name}, Visit $_currentVisitId');
      } else {
        _logger.w(_tag, 'No active visit found');
      }
    } catch (e) {
      _logger.e(_tag, 'Error loading current visit: $e');
      // Show error message if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkInTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_checkInTime!);
        
        // Format time as HH:MM:SS
        final hours = difference.inHours.toString().padLeft(2, '0');
        final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
        
        setState(() {
          _elapsedTime = "$hours:$minutes:$seconds";
        });
      }
    });
  }

  // Generic navigation method for all feature screens
  void _navigateToScreen(Widget Function(String storeId, String visitId) screenBuilder) {
    if (_currentStore != null && _currentVisitId != null) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => screenBuilder(
            _currentStore!.id!,
            _currentVisitId!,
          )
        )
      );
    } else {
      // Show error dialog if no active visit
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Active Visit'),
          content: const Text('You need to check-in to a store before you can access this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menus = [
      {
        'title': 'Sales Print Out', 
        'icon': Icons.print, 
        'onTap': () => _navigateToScreen((storeId, visitId) => SalesPrintOutScreen(storeId: storeId, visitId: visitId))
      },
      {
        'title': 'Open Ending', 
        'icon': Icons.inventory, 
        'onTap': () => _navigateToScreen((storeId, visitId) => OpenEndingScreen(storeId: storeId, visitId: visitId))
      },
      {'title': 'Activation', 'icon': Icons.check, 'onTap': () => _navigateToScreen((storeId, visitId) => ActivationScreen(store: Store()))},
      {'title': 'Out Of Stock', 'icon': Icons.warehouse, 'onTap': () => _navigateToScreen((storeId, visitId) => OutOfStockScreen(storeId: storeId, visitId: visitId))},
      {'title': 'Planogram', 'icon': Icons.view_module, 'onTap': () => _navigateToScreen((storeId, visitId) => ActivationScreen(store: Store()))},
      {'title': 'Price Monitoring', 'icon': Icons.attach_money, 'onTap': () => _navigateToScreen((storeId, visitId) => PriceMonitoringScreen(storeId: storeId, visitId: visitId))},
      {'title': 'Competitor', 'icon': Icons.people, 'onTap': () => _navigateToScreen((storeId, visitId) => PosmScreen(storeId: storeId, visitId: visitId))},
      {'title': 'POSM', 'icon': Icons.shopping_cart, 'onTap': () => _navigateToScreen((storeId, visitId) => PosmScreen(storeId: storeId, visitId: visitId))},
      {'title': 'Survey', 'icon': Icons.fact_check, 'onTap': () {}},
      {'title': 'Sampling Konsumen', 'icon': Icons.checklist, 'onTap': ()  => _navigateToScreen((storeId, visitId) => SamplingKonsumenScreen(storeId: storeId, visitId: visitId))},
      {'title': 'Promo Audit', 'icon': Icons.assignment_turned_in, 'onTap': () => _navigateToScreen((storeId, visitId) => PromoAuditListScreen())},
      {'title': 'Produk Listing', 'icon': Icons.list, 'onTap': () {}},
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Sales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Current visit info
                _buildCurrentVisitInfo(),
                const SizedBox(height: 16),
                
                // Grid menu
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    children: menus.map((menu) {
                      return GestureDetector(
                        onTap: menu['onTap'],
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(menu['icon'], size: 36, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              menu['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildCurrentVisitInfo() {
    if (_currentStore == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No active visit. Please check-in to a store first.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Active visit:\n${_currentStore?.name}, ${_currentStore?.province} - ${_currentStore?.area}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _elapsedTime,
              style: const TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier', // Monospace font for timer
              ),
            ),
          ),
        ],
      ),
    );
  }
}
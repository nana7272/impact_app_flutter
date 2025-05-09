import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/screens/pending_screen.dart';
import 'package:impact_app/screens/presentation_screen.dart';
import 'package:impact_app/screens/product_list_screen.dart';
import 'package:impact_app/screens/sales_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';
import 'package:impact_app/widget/header_home_widget.dart';
import 'package:impact_app/widget/rank_home_widget.dart';
import 'package:impact_app/widget/sales_line_chart.dart';
import 'package:impact_app/widget/target_widget.dart';
import 'package:impact_app/widget/visiting_bar_chart.dart';
import 'package:impact_app/api/api_services.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();
  final String _tag = 'HomeScreen';

  // Untuk user data
  Map<String, dynamic> _userData = {};
  bool _userDataLoaded = false;
  
  // Untuk current visit
  Store? _currentStore;
  String? _currentVisitId;
  DateTime? _checkInTime;
  ValueNotifier<String> _elapsedTime = ValueNotifier<String>("00:00:00");
  bool _isActiveVisit = false;
  bool _isCurrentVisitLoading = true;
  
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentVisit();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _elapsedTime.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString('userData');
      
      if (userData != null) {
        if (!_isDisposed) {
          setState(() {
            _userData = json.decode(userData);
            _userDataLoaded = true;
          });
        }
        _logger.d(_tag, 'User data loaded: ${_userData['name']}');
      }
    } catch (e) {
      _logger.e(_tag, 'Error loading user data: $e');
    }
  }

  Future<void> _loadCurrentVisit() async {
    if (_isDisposed) return;
    
    setState(() {
      _isCurrentVisitLoading = true;
    });

    try {
      // Fetch current visit data from API
      final currentVisitResponse = await _apiService.getCurrentVisit();
      
      if (_isDisposed) return;
      
      if (currentVisitResponse != null && 
          currentVisitResponse['data'] != null &&
          currentVisitResponse['data']['store_id'] != null) {
        
        final storeId = currentVisitResponse['data']['store_id'];
        final visitId = currentVisitResponse['data']['id'];
        
        // Parse check-in time
        DateTime? checkInTime;
        if (currentVisitResponse['data']['check_in_time'] != null) {
          checkInTime = DateTime.parse(currentVisitResponse['data']['check_in_time']);
        }
        
        // Fetch store details
        final storeResponse = await _apiService.getStoreById(storeId);
        
        if (_isDisposed) return;
        
        setState(() {
          _currentVisitId = visitId;
          _checkInTime = checkInTime;
          _currentStore = Store.fromJson(storeResponse['data']);
          _isActiveVisit = true;
          _isCurrentVisitLoading = false;
        });
        
        // Start timer outside setState to prevent unnecessary rebuilds
        if (checkInTime != null) {
          _startTimer();
        }
        
        _logger.d(_tag, 'Current visit loaded: Store ${_currentStore?.name}, Visit $_currentVisitId');
      } else {
        if (_isDisposed) return;
        
        setState(() {
          _isActiveVisit = false;
          _isCurrentVisitLoading = false;
          // Reset timer related values
          _checkInTime = null;
          _timer?.cancel();
          _timer = null;
          _elapsedTime.value = "00:00:00";
        });
        
        _logger.w(_tag, 'No active visit found');
      }
    } catch (e) {
      if (_isDisposed) return;
      
      setState(() {
        _isCurrentVisitLoading = false;
      });
      
      _logger.e(_tag, 'Error loading current visit: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    
    // Update timer immediately once
    _updateTimerValue();
    
    // Then start periodic updates
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimerValue();
    });
  }
  
  void _updateTimerValue() {
    if (_isDisposed || _checkInTime == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_checkInTime!);
    
    // Format time as HH:MM:SS
    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
    
    _elapsedTime.value = "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _userDataLoaded 
            ? _buildMainContent()
            : const Center(child: CircularProgressIndicator()),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Action for Check-in button
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => CheckinMapScreen(),
              ),
            ).then((_) {
              // Refresh current visit data when returning from check-in screen
              _loadCurrentVisit();
            });
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.location_on, color: Colors.white, size: 30),
          shape: const CircleBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomNavbar(
          currentIndex: _selectedIndex,
          onTabSelected: (i) => BottomMenu.onItemTapped(context, i),
          onCheckInPressed: () {},
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            HeaderHomedWidget(
              greeting: "Selamat Pagi,",
              name: _userData['name'] ?? "User",
              role: _userData['role'] ?? "Role",
              tlName: _userData['tlName'] ?? "Team Leader",
              region: _userData['region'] ?? "Region",
              province: _userData['province'] ?? "Province",
              area: _userData['area'] ?? "Area",
              onContactAdmin: () {
                // aksi jika tombol ditekan
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 8),
                      Text('April 2024', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RankWorkCardWidget(
                    rank: 3,
                    totalPeople: 30,
                    hoursWorked: 500,
                    totalHours: 1500,
                  ),
                  const SizedBox(height: 24),
                  SummaryCardWidget(
                    label1: "Target Call",
                    value1: "100",
                    label2: "Call",
                    value2: "50",
                    label3: "Achieve",
                    value3: "50%",
                  ),

                  SummaryCardWidget(
                    label1: "Target EC",
                    value1: "100",
                    label2: "EC",
                    value2: "50",
                    label3: "Achieve",
                    value3: "50%",
                  ),

                  SummaryCardWidget(
                    label1: "Target Val",
                    value1: "Rp1.000K",
                    label2: "Omzet",
                    value2: "Rp50K",
                    label3: "Achieve",
                    value3: "5%",
                  ),
                  const SizedBox(height: 24),
                  SalesLineChart(
                    dataPoints: [
                      FlSpot(0, 750000),
                      FlSpot(1, 500000),
                      FlSpot(2, 500000),
                      FlSpot(3, 200000),
                      FlSpot(4, 350000),
                      FlSpot(5, 500000),
                      FlSpot(6, 750000),
                    ],
                    labels: ['01 Feb', '02 Feb', '03 Feb', '04 Feb', '05 Feb', '06 Feb', '07 Feb'],
                    target: 1000000,
                  ),
                  const SizedBox(height: 24),
                  VisitingBarChart(
                    labels: ['01 Feb', '02 Feb', '03 Feb', '04 Feb', '05 Feb', '06 Feb'],
                    data: [
                      [500, 300, 250],
                      [750, 200, 240],
                      [500, 250, 200],
                      [250, 500, 200],
                      [750, 500, 250],
                      [500, 250, 200],
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    children: [
                      _buildMenuIcon(Icons.inventory, 'Product List', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => ProductListScreen()));
                      }),
                      _buildMenuIcon(Icons.attach_money, 'Sales', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => SalesScreen()));
                      }),
                      _buildMenuIcon(Icons.access_time, 'Pending', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => PendingScreen()));
                      }),
                      _buildMenuIcon(Icons.groups, 'Presentation', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => PresentationScreen()));
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('To Do List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ListTile(
                        title: Text('Toko Sinar Abadi'),
                        subtitle: Text('CI: 08:00 | CO: 08:30 | Durasi: 00:30'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      ListTile(
                        title: Text('Toko Berkah'),
                        subtitle: Text('Belum dikunjungi'),
                        trailing: Icon(Icons.cancel, color: Colors.red),
                      ),
                      ListTile(
                        title: Text('Trijaya Store'),
                        subtitle: Text('Belum dikunjungi'),
                        trailing: Icon(Icons.cancel, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Current active visit with real-time timer
                  _buildCurrentVisitInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData iconData, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCurrentVisitInfo() {
    if (_isCurrentVisitLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(width: 12),
            Text('Loading visit information...'),
          ],
        ),
      );
    }
    
    if (!_isActiveVisit || _currentStore == null) {
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
                'No active visit. Please check-in to a store.',
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
              'Anda sedang mengunjungi outlet:\n${_currentStore?.name}, ${_currentStore?.province} - ${_currentStore?.area}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _elapsedTime,
              builder: (context, value, child) {
                return Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier', // Monospace font for timer
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
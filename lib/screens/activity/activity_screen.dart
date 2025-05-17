// screens/activity/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/tabview/activation_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/attendance_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/availability_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/competitor_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/oos_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/open_ending_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/planogram_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/posm_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/price_monitoring_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/sampling_konsumen_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/spo_tab_view.dart';
import 'package:impact_app/screens/activity/tabview/survey_tab_view.dart';
import 'package:impact_app/screens/checkin/checin_screen.dart'; // Pastikan path ini benar
import 'package:impact_app/utils/bottom_menu_handler.dart'; // Pastikan path ini benar
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart'; // Pastikan path ini benar
import 'package:provider/provider.dart';


class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityProvider(),
      child: const _ActivityScreenContent(),
    );
  }
}

class _ActivityScreenContent extends StatefulWidget {
  const _ActivityScreenContent({Key? key}) : super(key: key);

  @override
  State<_ActivityScreenContent> createState() => _ActivityScreenContentState();
}

class _ActivityScreenContentState extends State<_ActivityScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavSelectedIndex = 1; // Asumsikan Activity adalah index ke-1 untuk BottomNav

  // Urutan tab yang akan ditampilkan. Sesuaikan jika perlu.
  final List<String> _tabNames = [
    'Attendance',    // Index 0
    'SPO',           // Index 1
    'POSM',    // Index 2 (Ini akan menampilkan POSM)
    'Availability',  // Index 3
    'OOS',           // Index 4
    'Price Monitoring',     // Index 5
    'Activation',    // Index 6
    'Planogram',     // Index 7
    'Sampling Konsumen',      // Index 8 (Sampling Konsumen)
    'Survey',        // Index 9
    'Open Endind',
    'Competitor'      // Index 10
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
    final provider = Provider.of<ActivityProvider>(context, listen: false);

    // Pemuatan data awal untuk tab pertama (Attendance)
    // dipanggil setelah frame pertama selesai dibangun untuk menghindari error '!_dirty'.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDataForCurrentTab(provider, _tabController.index, forceLoad: true);
      }
    });

    _tabController.addListener(() {
      if (mounted) {
        if (_tabController.indexIsChanging) {
          setState(() {}); // Untuk update indikator tab jika ada styling khusus
        }
        // Selalu load data saat tab diklik (forceLoad: true)
        _loadDataForCurrentTab(provider, _tabController.index, forceLoad: true);
      }
    });
  }

  void _loadDataForCurrentTab(ActivityProvider provider, int tabIndex, {bool forceLoad = false}) {
    // Cek apakah perlu memuat: state masih initial ATAU dipaksa refresh (forceLoad = true)
    // Ini membantu menghindari pemanggilan API berulang jika data sudah ada dan tidak ada paksaan refresh.
    // Untuk pemanggilan dari tab listener, forceLoad = true akan selalu memuat ulang.
    // Untuk pemanggilan awal dari initState (via addPostFrameCallback), forceLoad = true juga memastikan data dimuat.

    switch (tabIndex) {
      case 0: // Attendance
        if (provider.attendanceDataState == DataState.initial || forceLoad) {
          provider.loadAttendanceReportData(forceRefresh: forceLoad);
        }
        break;
      case 1: // SPO
        if (provider.spoDataState == DataState.initial || forceLoad) {
          provider.loadSalesData(forceRefresh: forceLoad);
        }
        break;
      case 2: // Competitor (POSM)
        if (provider.posmDataState == DataState.initial || forceLoad) {
          provider.loadPosmReportData(forceRefresh: forceLoad);
        }
        break;
      case 3: // Availability
        if (provider.availabilityDataState == DataState.initial || forceLoad) {
          provider.loadStockReportData(forceRefresh: forceLoad);
        }
        break;
      case 4: // OOS
        if (provider.oosDataState == DataState.initial || forceLoad) {
          provider.loadOosReportData(forceRefresh: forceLoad);
        }
        break;
      case 5: // Price Monitoring
        if (provider.priceMonitoringDataState == DataState.initial || forceLoad) {
          provider.loadPriceMonitoringReportData(forceRefresh: forceLoad);
        }
        break;
      case 6: // Activation
        if (provider.activationDataState == DataState.initial || forceLoad) {
          provider.loadActivationReportData(forceRefresh: forceLoad);
        }
        break;
      case 7: // Planogram
        if (provider.planogramDataState == DataState.initial || forceLoad) {
          provider.loadPlanogramReportData(forceRefresh: forceLoad);
        }
        break;
      case 8: // Sampling Konsumen
        if (provider.samplingKonsumenDataState == DataState.initial || forceLoad) {
          provider.loadSamplingKonsumenReportData(forceRefresh: forceLoad);
        }
        break;
      case 9: // Survey
        if (provider.surveyDataState == DataState.initial || forceLoad) {
          provider.loadSurveyReportData(forceRefresh: forceLoad);
        }
        break;
      case 10: // Open Ending
        if (provider.openEndingDataState == DataState.initial || forceLoad) {
          provider.loadOpenEndingReportData(forceRefresh: forceLoad);
        }
        break;
      case 11: // Open Ending
        if (provider.openEndingDataState == DataState.initial || forceLoad) {
          provider.loadCompetitorReportData(forceRefresh: forceLoad);
        }
        break;
      default:
        // Tab tidak dikenal
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan instance provider untuk digunakan dalam date picker callback jika perlu
    // Namun, karena DateSelectorWidget ada di dalam setiap TabView yang merupakan Consumer,
    // lebih baik DateSelectorWidget mendapatkan provider-nya sendiri.
    // final activityProvider = Provider.of<ActivityProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Activity History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[700],
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue[700],
          ),
          tabs: _tabNames.map((name) => _buildTab(name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ // Pastikan semua view adalah const jika tidak ada parameter dinamis
          AttendanceTabView(),
          SpoTabView(),
          PosmTabView(), // Ini adalah view untuk "Competitor"
          AvailabilityTabView(),
          OosTabView(),
          PriceMonitoringTabView(),
          ActivationTabView(),
          PlanogramTabView(),
          SamplingKonsumenTabView(),
          SurveyTabView(),
          OpenEndingTabView(),
          CompetitorTabView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const CheckinMapScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.location_on, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _bottomNavSelectedIndex,
        onTabSelected: (i) {
          BottomMenu.onItemTapped(context, i);
          // Jika BottomMenu.onItemTapped tidak menangani update _bottomNavSelectedIndex:
          // setState(() {
          //   _bottomNavSelectedIndex = i;
          // });
        },
        onCheckInPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const CheckinMapScreen()));
        },
      ),
    );
  }

  Widget _buildTab(String text) {
    // Sesuaikan padding dan fontSize agar semua nama tab muat
    double fontSize = 11;
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8); // Default padding

    if (_tabNames.length > 7) { // Jika tab banyak, perkecil sedikit
        fontSize = 10.5;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8);
    }


    return Tab(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize)),
      ),
    );
  }
}
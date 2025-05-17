import 'package:flutter/material.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/activation/activation_offline_list_screen.dart';
import 'package:impact_app/screens/product/availability/availability_offline_list_screen.dart';
import 'package:impact_app/screens/product/competitor/competitor_offline_list_screen.dart';
import 'package:impact_app/screens/product/oos/model/oos_item_model.dart';
import 'package:impact_app/screens/product/oos/oos_offline_list_screen.dart';
import 'package:impact_app/screens/product/open_ending/open_ending_offline_list_screen.dart';
import 'package:impact_app/screens/product/planogram/planogram_offline_list_screen.dart';
import 'package:impact_app/screens/product/posm/posm_offline_list_screen.dart';
import 'package:impact_app/screens/product/price_monitoring/price_monitoring_offline_list_screen.dart';
import 'package:impact_app/screens/product/sales_print_out/sales_print_out_offline_list_screen.dart';
import 'package:impact_app/screens/product/sampling_konsument/sampling_konsumen_offline_list_screen.dart';
import 'package:impact_app/screens/product/survey/survey_offline_list_screen.dart';

class PendingScreen extends StatefulWidget {
  
  const PendingScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  
  List<Map<String, dynamic>> pendingData = [];
  @override
  initState() {
    super.initState();
    getDataPending();
  }

  Future<void> getDataPending() async {
    final List<Map<String, dynamic>> pendingData = [
      {"icon": Icons.check, "count": 0, "title": "Data Absen CI"},
      {"icon": Icons.check, "count": 0, "title": "Data Absen CO"},
      {"icon": Icons.monetization_on, "count": 0, "title": "Promo Audit"},
    ];

    final List<Map<String, dynamic>> rawDataSPO = await DatabaseHelper.instance.getAllSalesPrintOuts();
    final List<Map<String, dynamic>> rawDataOpenEdning = await DatabaseHelper.instance.getAllOpenEndingData();
    final List<Map<String, dynamic>> rawDataPOSM = await DatabaseHelper.instance.getAllUnsyncedPosmEntries();
    final List<OOSItem> rawDataOOS = await DatabaseHelper.instance.getUnsyncedOOSItems();
    final List<Map<String, dynamic>> rawDataActivation = await DatabaseHelper.instance.getUnsyncedActivationEntries();
    final List<Map<String, dynamic>> rawDataPriceM = await DatabaseHelper.instance.getUnsyncedPriceMonitoringEntries();
    final List<Map<String, dynamic>> rawDataComp = await DatabaseHelper.instance.getUnsyncedPromoActivityEntries();
    final List<Map<String, dynamic>> rawDataPla = await DatabaseHelper.instance.getUnsyncedPlanogramEntries();
    final List<Map<String, dynamic>> rawDataSamplingKonsument = await DatabaseHelper.instance.getUnsyncedSamplingKonsumenEntries();
    final List<Map<String, dynamic>> radDataAvai = await DatabaseHelper.instance.getUnsyncedAvailabilityHeadersWithItems();
    final List<Map<String, dynamic>> rawdataSurvey = await DatabaseHelper.instance.getUnsyncedSurveyResponses();
    
    pendingData.add(
      {"icon": Icons.print, "count": rawDataSPO.length, "title": "Sales Print Out"},
    );

    pendingData.add(
      {"icon": Icons.inventory, "count": rawDataOpenEdning.length, "title": "Open Ending"},
    );

    pendingData.add(
      {"icon": Icons.storefront, "count": rawDataPOSM.length, "title": "POSM"},
    );

    pendingData.add(
      {"icon": Icons.inventory, "count": rawDataOOS.length, "title": "Out of Stock"},
    );

    pendingData.add(
      {"icon": Icons.campaign, "count": rawDataActivation.length, "title": "Activation"},
    );

    pendingData.add(
      {"icon": Icons.attach_money, "count": rawDataPriceM.length, "title": "Price Monitoring"},
    );

    pendingData.add(
      {"icon": Icons.groups, "count": rawDataComp.length, "title": "Competitor"},
    );

    pendingData.add(
      {"icon": Icons.storefront, "count": rawDataPla.length, "title": "Planogram"},
    );

    pendingData.add(
      {"icon": Icons.check, "count": rawDataSamplingKonsument.length, "title": "Sampling Konsumen"},
    );

    pendingData.add(
      {"icon": Icons.inventory_2, "count": radDataAvai.length, "title": "Availability"},
    );

    pendingData.add(
      {"icon": Icons.fact_check, "count": rawdataSurvey.length, "title": "Survey"},
    );

    setState(() {
      this.pendingData = pendingData;
    });
  }

  void _navigateToDetail(BuildContext context, String title) {
      // Placeholder untuk navigasi sebenarnya.
      // Ganti SnackBar ini dengan Navigator.pushNamed atau Navigator.push
      // ke halaman detail yang sesuai.
      String message = 'Navigasi ke detail: $title';
      // String? routeName;

      switch (title) {
        case "Sales Print Out":
        
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesPrintOutOfflineListScreen(),
            ),
          ).then((value) {
            getDataPending();
          });
          break;
        case "Open Ending":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OpenEndingOfflineListScreen(),
            ),
          ).then((value) {
            getDataPending();
          });
          break;
        case "POSM":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PosmOfflineListScreen(),
            ),
          ).then((value) {
            getDataPending();
          });
          break;

          case "Out of Stock":
          Navigator.push(
            context,
          MaterialPageRoute(builder: (context) => const OosOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;
        case "Activation":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActivationOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;
        case "Price Monitoring":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PriceMonitoringOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;

        case "Competitor":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CompetitorOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;

        case "Planogram":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlanogramOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;
        case "Sampling Konsumen":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SamplingKonsumenOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;

          case "Availability":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AvailabilityOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;

          case "Survey":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SurveyOfflineListScreen()),
          ).then((value) {
            getDataPending();
          });
          break;

          
       
        default:
          message = 'Halaman detail untuk "$title" belum diimplementasikan.';
      }

      // if (routeName != null) {
      //   Navigator.pushNamed(context, routeName);
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(message)),
      //   );
      // }
      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }


  @override
  Widget build(BuildContext context) {
  
    // Fungsi untuk menangani ketika item di-tap
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Pending Data Offline'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: pendingData.length,
                itemBuilder: (context, index) {
                  final item = pendingData[index];
                  return Card(
                    color: Colors.grey.shade800,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(item['icon'], color: Colors.green, size: 32),
                      title: Text('${item['count']}', style: TextStyle(color: Colors.white, fontSize: 20),),
                      subtitle: Text(item['title'], style: const TextStyle(color: Colors.white)),
                      trailing: const Text('Klik Detail', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _navigateToDetail(context, item['title'] as String);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Kirim Semua Data', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

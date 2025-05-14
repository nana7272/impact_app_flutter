import 'package:flutter/material.dart';
import 'package:impact_app/database/database_helper.dart';
import 'package:impact_app/screens/product/sales_print_out/sales_print_out_offline_list_screen.dart';
import 'package:impact_app/screens/product/sales_print_out/sales_print_out_screen.dart';

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
      {"icon": Icons.inventory, "count": 0, "title": "Open Ending"},
      {"icon": Icons.storefront, "count": 0, "title": "POSM"},
      {"icon": Icons.inventory, "count": 0, "title": "Out of Stock"},
      {"icon": Icons.check, "count": 0, "title": "Activation"},
      {"icon": Icons.fact_check, "count": 0, "title": "Survey"},
      {"icon": Icons.storefront, "count": 0, "title": "Planogram"},
      {"icon": Icons.attach_money, "count": 0, "title": "Price Monitoring"},
      {"icon": Icons.groups, "count": 0, "title": "Competitor"},
      {"icon": Icons.inventory_2, "count": 0, "title": "Availability"},
      {"icon": Icons.check, "count": 0, "title": "Sampling Konsumen"},
      {"icon": Icons.monetization_on, "count": 0, "title": "Promo Audit"},
    ];

    final List<Map<String, dynamic>> rawData = await DatabaseHelper.instance.getAllSalesPrintOuts();
    pendingData.add(
      {"icon": Icons.print, "count": rawData.length, "title": "Sales Print Out"},
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
        case "Data Absen CO":
          // routeName = '/pending_absen_co_detail';
          break;
        case "Sales Print Out":
          // routeName = '/pending_sales_print_out_detail';
          break;
        // Tambahkan case untuk setiap title lainnya
        // case "Open Ending":
        //   routeName = '/pending_open_ending_detail';
        //   break;
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

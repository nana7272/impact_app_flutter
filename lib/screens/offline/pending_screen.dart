import 'package:flutter/material.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pendingData = [
      {"icon": Icons.check, "count": 5, "title": "Data Absen CI"},
      {"icon": Icons.check, "count": 10, "title": "Data Absen CO"},
      {"icon": Icons.print, "count": 25, "title": "Sales Print Out"},
      {"icon": Icons.inventory, "count": 3, "title": "Open Ending"},
      {"icon": Icons.storefront, "count": 8, "title": "POSM"},
      {"icon": Icons.inventory, "count": 5, "title": "Out of Stock"},
      {"icon": Icons.check, "count": 6, "title": "Activation"},
      {"icon": Icons.fact_check, "count": 7, "title": "Survey"},
      {"icon": Icons.storefront, "count": 9, "title": "Planogram"},
      {"icon": Icons.attach_money, "count": 9, "title": "Price Monitoring"},
      {"icon": Icons.groups, "count": 9, "title": "Competitor"},
      {"icon": Icons.inventory_2, "count": 9, "title": "Availability"},
      {"icon": Icons.check, "count": 9, "title": "Sampling Konsumen"},
      {"icon": Icons.monetization_on, "count": 9, "title": "Promo Audit"},
    ];

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

import 'package:flutter/material.dart';
import 'package:impact_app/models/sales_print_out_model.dart';
import 'package:impact_app/screens/sales_print_out_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menus = [
      {'title': 'Sales Print Out', 'icon': Icons.print},
      {'title': 'Open Ending', 'icon': Icons.inventory},
      {'title': 'Activation', 'icon': Icons.check},
      {'title': 'Out Of Stock', 'icon': Icons.warehouse},
      {'title': 'Planogram', 'icon': Icons.view_module},
      {'title': 'Price Monitoring', 'icon': Icons.attach_money},
      {'title': 'Competitor', 'icon': Icons.people},
      {'title': 'POSM', 'icon': Icons.shopping_cart},
      {'title': 'Survey', 'icon': Icons.fact_check},
      {'title': 'Sampling Konsumen', 'icon': Icons.checklist},
      {'title': 'Promo Audit', 'icon': Icons.assignment_turned_in},
      {'title': 'Produk Listing', 'icon': Icons.list},
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Anda sedang mengunjungi outlet:\nTK Rindu Jaya, DKI Jakarta - Jaktim - GT',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '00:16:30',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: menus.map((menu) {
                  return Column(
                    children: [
                      GestureDetector(
                      onTap: () {
                         if (menu['title'] == 'Sales Print Out') {
                           Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => SalesPrintOutScreen(storeId: "1",
        visitId: "1")));
                         }
                       },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(menu['icon'], size: 36, color: Colors.black87),
                      )),
                      const SizedBox(height: 8),
                      Text(menu['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

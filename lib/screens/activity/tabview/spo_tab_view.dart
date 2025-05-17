// screens/activity/views/spo_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/sales_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SpoTabView extends StatefulWidget {
  const SpoTabView({Key? key}) : super(key: key);

  @override
  State<SpoTabView> createState() => _SpoTabViewState();
}

class _SpoTabViewState extends State<SpoTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Untuk menjaga state saat tab tidak aktif

  @override
  void initState() {
    super.initState();
    // Panggil load data saat widget pertama kali dibuat jika belum ada data
    // atau jika kita ingin selalu refresh saat tab ini ditampilkan
    // Provider.of<ActivityProvider>(context, listen: false).loadSalesData();
    // Pemuatan data akan ditangani oleh listener TabController di ActivityScreen
    // atau saat tanggal berubah
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Penting untuk AutomaticKeepAliveClientMixin
    final provider = Provider.of<ActivityProvider>(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        children: [
          DateSelectorWidget(
            onDateChanged: () {
              provider.loadSalesData(forceRefresh: true);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ActivityProvider provider) {
    switch (provider.spoDataState) {
      case DataState.initial:
        // Bisa tampilkan pesan atau panggil load data jika ini adalah tab awal
        // Untuk sekarang, biarkan loading atau pesan kosong
        return const Center(
            child: Text("Pilih tanggal untuk memuat data SPO."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.spoErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadSalesData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.salesReports.isEmpty) {
          return const Center(
              child: Text('Tidak ada data SPO untuk tanggal ini.',
                  style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70), // Padding untuk FAB
          itemCount: provider.salesReports.length,
          itemBuilder: (context, index) {
            final report = provider.salesReports[index];
            return _buildSpoCard(context, report);
          },
        );
    }
  }

  Widget _buildSpoCard(BuildContext context, SalesReport report) {
    String displayTransactionDate = report.transactionDate;
    try {
      DateTime parsedDate =
          DateFormat("d MMMM yyyy", "en_US").parse(report.transactionDate);
      displayTransactionDate =
          DateFormat("dd MMMM yyyy", "id_ID").format(parsedDate);
    } catch (e) {
      print(
          "Error parsing SPO transaction date: ${report.transactionDate} - $e");
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(children: [
              const Icon(Icons.storefront_outlined,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(report.outletName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 6, bottom: 8),
            child: Text(displayTransactionDate,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.5)
              },
              children: [
                TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Product',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 13))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Quantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 13))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Value',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 13))),
                ]),
                TableRow(children: [
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                ]),
                for (var product in report.products)
                  TableRow(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                        child: Text(product.productName,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13))),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                        child: Text(product.quantity.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13))),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                        child: Text(
                            NumberFormat("#,##0", "id_ID")
                                .format(product.value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 13))),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
            child: Row(children: [
              Text('Motorist: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              Expanded(
                  child: Text(report.motoristName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
      ),
    );
  }
}

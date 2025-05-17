// screens/activity/views/price_monitoring_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/price_monitoring_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PriceMonitoringTabView extends StatefulWidget {
  const PriceMonitoringTabView({Key? key}) : super(key: key);

  @override
  State<PriceMonitoringTabView> createState() => _PriceMonitoringTabViewState();
}

class _PriceMonitoringTabViewState extends State<PriceMonitoringTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<ActivityProvider>(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        children: [
          DateSelectorWidget(
            onDateChanged: () {
              provider.loadPriceMonitoringReportData(forceRefresh: true);
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
    switch (provider.priceMonitoringDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Price Monitoring."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.priceMonitoringErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadPriceMonitoringReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.priceMonitoringReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Price Monitoring untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.priceMonitoringReports.length,
          itemBuilder: (context, index) {
            final report = provider.priceMonitoringReports[index];
            return _buildPriceOutletCard(context, report);
          },
        );
    }
  }

  Widget _buildPriceOutletCard(BuildContext context, PriceMonitoringReport report) {
    // Format transaction_datetime: "15-05-2025 14:49" ke "dd-MM-yyyy HH:mm"
    String displayTransactionDateTime = report.transactionDatetime;
    try {
        DateTime parsedDateTime = DateFormat("dd-MM-yyyy HH:mm").parse(report.transactionDatetime);
        // Sesuai UI: "03-03-2024 07:34"
        displayTransactionDateTime = DateFormat("dd-MM-yyyy HH:mm").format(parsedDateTime);
    } catch (e) {
        print("Error parsing Price Monitoring transaction datetime: ${report.transactionDatetime} - $e");
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Outlet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue[600], // Warna header biru seperti UI
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column( // Ditumpuk vertikal untuk nama outlet dan tanggal
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.outletName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                 Text(
                  displayTransactionDateTime, // Tanggal dan waktu transaksi
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
           // Alamat Outlet di bawah header
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
            child: Text(
              report.outletAddress,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Tabel Produk
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5), // Product
                1: FlexColumnWidth(1.5), // Harga Normal
                2: FlexColumnWidth(1.5), // Harga Promo
              },
              children: [
                // Header Tabel
                TableRow(
                  children: [
                    _buildTableHeader('Product'),
                    _buildTableHeader('Harga Normal', alignment: TextAlign.right),
                    _buildTableHeader('Harga Promo', alignment: TextAlign.right),
                  ],
                ),
                // Garis Pemisah
                TableRow(children: [
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                ]),
                // Data Produk
                for (var product in report.products)
                  TableRow(
                    children: [
                      _buildTableCell(product.productName),
                      _buildTableCell(product.hargaNormal, alignment: TextAlign.right),
                      _buildTableCell(product.hargaPromo, alignment: TextAlign.right),
                    ],
                  ),
              ],
            ),
          ),
          // Notes (Jika ada)
          if (report.notes != null && report.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text('Notes:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 2),
                  Text(report.notes!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          // Nama Motorist
          Padding(
            padding: EdgeInsets.fromLTRB(12.0, (report.notes != null && report.notes!.isNotEmpty ? 4.0 : 8.0) , 12.0, 12.0),
            child: Column(
              children: [
                if (report.notes == null || report.notes!.isEmpty) const Divider(), // Tambah divider jika tidak ada notes
                 Row(
                    children: [
                      Text('Motorist: ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      Expanded(
                        child: Text(
                          report.motoristName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text, textAlign: alignment, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13)),
    );
  }

  Widget _buildTableCell(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Text(text, textAlign: alignment, style: const TextStyle(color: Colors.black87, fontSize: 13)),
    );
  }
}
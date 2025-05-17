// screens/activity/views/availability_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/stock_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AvailabilityTabView extends StatefulWidget {
  const AvailabilityTabView({Key? key}) : super(key: key);

  @override
  State<AvailabilityTabView> createState() => _AvailabilityTabViewState();
}

class _AvailabilityTabViewState extends State<AvailabilityTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Pemuatan data akan ditangani oleh listener TabController di ActivityScreen
    // atau saat tanggal berubah
  }

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
              provider.loadStockReportData(forceRefresh: true);
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
    switch (provider.availabilityDataState) {
      case DataState.initial:
        return const Center(
            child: Text("Pilih tanggal untuk memuat data ketersediaan."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.availabilityErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadStockReportData(forceRefresh: true),
        );
      case DataState.loaded:
        final stockReport = provider.stockReport;
        if (stockReport == null || stockReport.details.isEmpty) {
          return const Center(
              child: Text('Tidak ada data ketersediaan untuk tanggal ini.',
                  style: TextStyle(fontSize: 16)));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(children: [
                Expanded(
                    child: _buildSummaryCard(
                        title: "Stok Tersedia",
                        count: stockReport.summary.stokTersedia,
                        color: Colors.green)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSummaryCard(
                        title: "Stok Tidak Tersedia",
                        count: stockReport.summary.stokTidakTersedia,
                        color: Colors.red)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 70),
                itemCount: stockReport.details.length,
                itemBuilder: (context, index) {
                  final detail = stockReport.details[index];
                  return _buildStockDetailCard(context, detail);
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSummaryCard(
      {required String title, required int count, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(count.toString(),
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildStockDetailCard(BuildContext context, StockDetail detail) {
    String displayTransactionDateTime = detail.transactionDatetime;
    try {
      DateTime parsedDateTime =
          DateFormat("dd-MM-yyyy HH:mm").parse(detail.transactionDatetime);
      displayTransactionDateTime =
          DateFormat("dd-MM-yyyy HH:mm", "id_ID").format(parsedDateTime);
    } catch (e) {
      print(
          "Error parsing stock transaction datetime: ${detail.transactionDatetime} - $e");
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
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(detail.outletName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis)),
                  Text(displayTransactionDateTime,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: Text(detail.outletAddress,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2)
              },
              children: [
                TableRow(children: [
                  _buildTableHeader('Product'),
                  _buildTableHeader('Stok Gudang', alignment: TextAlign.center),
                  _buildTableHeader('Stok Display',
                      alignment: TextAlign.center),
                  _buildTableHeader('Total Stok', alignment: TextAlign.center),
                ]),
                TableRow(children: [
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                  Divider(color: Colors.grey[300], height: 1, thickness: 1),
                ]),
                for (var item in detail.items)
                  TableRow(children: [
                    _buildTableCell(item.productName),
                    _buildTableCell(item.stockGudang.toString(),
                        alignment: TextAlign.center),
                    _buildTableCell(item.stockDisplay.toString(),
                        alignment: TextAlign.center),
                    _buildTableCell(item.totalStock.toString(),
                        alignment: TextAlign.center),
                  ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
            child: Row(children: [
              Text('Motorist: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              Expanded(
                  child: Text(detail.motoristName,
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

  Widget _buildTableHeader(String text,
      {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text,
          textAlign: alignment,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 13)),
    );
  }

  Widget _buildTableCell(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Text(text,
          textAlign: alignment,
          style: const TextStyle(color: Colors.black87, fontSize: 13)),
    );
  }
}

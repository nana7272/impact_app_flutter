// screens/activity/views/oos_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/oos_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OosTabView extends StatefulWidget {
  const OosTabView({Key? key}) : super(key: key);

  @override
  State<OosTabView> createState() => _OosTabViewState();
}

class _OosTabViewState extends State<OosTabView> with AutomaticKeepAliveClientMixin {
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
              provider.loadOosReportData(forceRefresh: true);
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
    switch (provider.oosDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data OOS."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.oosErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadOosReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.oosReports.isEmpty) {
          return const Center(child: Text('Tidak ada data OOS untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.oosReports.length,
          itemBuilder: (context, index) {
            final report = provider.oosReports[index];
            return _buildOosOutletCard(context, report, provider);
          },
        );
    }
  }

  Widget _buildOosOutletCard(BuildContext context, OosReport report, ActivityProvider provider) {
    // Format tanggal transaksi dari API (misal "15 May 2025") ke "04 March 2024" (sesuai UI Card)
    String displayTransactionDate = provider.formattedSelectedDateForHeaderCard; // Fallback
    try {
        DateTime parsedApiDate = DateFormat("d MMMM yyyy", "en_US").parse(report.transactionDate);
        displayTransactionDate = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedApiDate); // Sesuai UI
    } catch (e) {
        print("Error parsing OOS transaction date: ${report.transactionDate} - $e");
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_outlined, color: Colors.blue[700], size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.outletName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 2),
                  child: Text(
                    displayTransactionDate, // Menggunakan tanggal yang sudah diformat
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          // Daftar Produk OOS
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.products.length,
            itemBuilder: (context, productIndex) {
              final product = report.products[productIndex];
              return _buildOosProductItemCard(context, product);
            },
          ),
          // Nama Motorist
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildOosProductItemCard(BuildContext context, OosProduct product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: product.getCardColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: product.getCardColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Produk (Header Kartu Produk)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: product.getCardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              product.productName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          // Detail Quantity dan Keterangan
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOosField("Quantity", product.quantity.toString()),
                const SizedBox(height: 8),
                _buildOosField("Keterangan", product.keterangan),
                const SizedBox(height: 10),
                Align( // Untuk meletakkan chip status di tengah atau sesuai preferensi
                  alignment: Alignment.centerLeft, // Atau Alignment.center
                  child: _buildOosStatusChip(product.availabilityStatus, product.getStatusChipColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOosField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildOosStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}
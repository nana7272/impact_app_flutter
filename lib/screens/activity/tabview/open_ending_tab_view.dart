// screens/activity/views/open_ending_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/open_ending_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OpenEndingTabView extends StatefulWidget {
  const OpenEndingTabView({Key? key}) : super(key: key);

  @override
  State<OpenEndingTabView> createState() => _OpenEndingTabViewState();
}

class _OpenEndingTabViewState extends State<OpenEndingTabView> with AutomaticKeepAliveClientMixin {
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
              provider.loadOpenEndingReportData(forceRefresh: true);
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
    switch (provider.openEndingDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Open Ending."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.openEndingErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadOpenEndingReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.openEndingReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Open Ending untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.openEndingReports.length,
          itemBuilder: (context, index) {
            final report = provider.openEndingReports[index];
            return _buildOpenEndingOutletCard(context, report);
          },
        );
    }
  }

  Widget _buildOpenEndingOutletCard(BuildContext context, OpenEndingReport report) {
    String displayTransactionDate = report.transactionDate;
    try {
        // API: "15 May 2025", UI: "04 March 2024"
        // Kita akan format tanggal dari API ke format yang ada di provider (dd MMMM yy)
        DateTime parsedApiDate = DateFormat("d MMMM yyyy", "en_US").parse(report.transactionDate);
        displayTransactionDate = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedApiDate);
    } catch (e) {
        print("Error parsing OpenEnding transaction date: ${report.transactionDate} - $e");
        // Jika gagal parse, gunakan tanggal dari provider (selectedDate) sebagai fallback
        // Ini mungkin tidak selalu akurat jika API mengembalikan tanggal transaksi yang berbeda
        displayTransactionDate = Provider.of<ActivityProvider>(context, listen: false).formattedSelectedDateForDisplay;
    }


    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white, // Latar belakang kartu utama
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Outlet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Warna header outlet, sesuaikan jika perlu
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
                  padding: const EdgeInsets.only(left: 30.0, top: 2), // Align with text
                  child: Text(
                    displayTransactionDate, // Tanggal dari provider yang sudah diformat
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          // Daftar Produk
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.products.length,
            itemBuilder: (context, productIndex) {
              final product = report.products[productIndex];
              return _buildProductItemCard(context, product);
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

  Widget _buildProductItemCard(BuildContext context, OpenEndingProduct product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: product.getCardColor.withOpacity(0.15), // Latar belakang kartu produk dengan opacity
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: product.getCardColor, width: 1.5), // Border dengan warna solid
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Produk (Header Kartu Produk)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: product.getCardColor, // Warna solid untuk header produk
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7), // Disesuaikan dengan border container
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              product.productName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          // Detail Stok (Open, In, Ending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockField("Open", product.openStock.toString()),
                _buildStockField("In", product.inStock.toString()),
                _buildStockField("Ending", product.endingStock.toString()),
              ],
            ),
          ),
          // Sell Out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: _buildStockField("Sell out", product.sellOut ?? "0", isWide: true), // Tampilkan 0 jika null
          ),
          // Stock Return & Stock Expired
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 10.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStockStatusChip("Stock Return : ${product.stockReturn}", Colors.blue.shade600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStockStatusChip("Stock Expired : ${product.stockExpired}", Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockField(String label, String value, {bool isWide = false}) {
    return Expanded( // Agar semua field memiliki ruang yang sama atau bisa diatur
      flex: isWide ? 3 : 1, // Sell out lebih lebar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Container(
            width: double.infinity, // Memenuhi expanded width
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              value,
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
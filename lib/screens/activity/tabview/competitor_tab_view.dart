// screens/activity/views/competitor_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/competitor_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class CompetitorTabView extends StatefulWidget {
  const CompetitorTabView({Key? key}) : super(key: key);

  @override
  State<CompetitorTabView> createState() => _CompetitorTabViewState();
}

class _CompetitorTabViewState extends State<CompetitorTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showEnlargedImage(BuildContext context, String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
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
              provider.loadCompetitorReportData(forceRefresh: true);
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
    switch (provider.competitorDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Kompetitor."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.competitorErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadCompetitorReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.competitorReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Kompetitor untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.competitorReports.length,
          itemBuilder: (context, index) {
            final report = provider.competitorReports[index];
            return _buildCompetitorOutletCard(context, report);
          },
        );
    }
  }

  Widget _buildCompetitorOutletCard(BuildContext context, CompetitorReport report) {
    // Format periode "14 May 2025 - 15 May 2025" ke "09 Feb - 10 Feb 2024" (atau sesuai API)
    // Untuk contoh ini, kita akan coba format ulang jika memungkinkan, atau tampilkan apa adanya.
    String displayPeriode = report.periode;
    try {
      // Asumsi format API adalah "d MMMM yyyy - d MMMM yyyy"
      var parts = report.periode.split(' - ');
      if (parts.length == 2) {
        DateTime startDate = DateFormat("d MMMM yyyy", "en_US").parse(parts[0]);
        DateTime endDate = DateFormat("d MMMM yyyy", "en_US").parse(parts[1]);
        // Format ke "09 Feb - 10 Feb 2024" (jika tahun sama)
        // atau "09 Feb 2023 - 10 Mar 2024" (jika tahun beda)
        String startDayMonth = DateFormat('dd MMM', 'id_ID').format(startDate);
        String endDayMonth = DateFormat('dd MMM', 'id_ID').format(endDate);
        if (startDate.year == endDate.year) {
          displayPeriode = "$startDayMonth - $endDayMonth ${endDate.year}";
        } else {
          displayPeriode = "${DateFormat('dd MMM yyyy', 'id_ID').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(endDate)}";
        }
      }
    } catch (e) {
      print("Error parsing periode: ${report.periode} - $e");
      // Biarkan displayPeriode menggunakan nilai asli dari API jika parsing gagal
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
              color: Colors.blue[600], // Warna header biru
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.outletName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      const Text("Periode:", style: TextStyle(fontSize: 11, color: Colors.white70)),
                      Text(
                        displayPeriode, // Periode
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                  ],
                )
              ],
            ),
          ),
          // Alamat Outlet
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
            child: Text(
              report.outletAddress,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Product Own Section
          _buildProductSection(context, "Product Own", report.productOwn),
          const SizedBox(height: 8),
          // Product Competitor Section
          _buildProductSection(context, "Product Competitor", report.productCompetitor),

          // Nama Motorist
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 12.0),
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

  Widget _buildProductSection(BuildContext context, String title, ProductSection section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          if (section.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showEnlargedImage(context, section.imageUrl, title),
              child: Center( // Pusatkan gambar section
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: section.imageUrl,
                    height: 100, // Tinggi gambar section
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(height: 100, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 30)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Tabel Produk
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Product
              1: FlexColumnWidth(1.5), // Harga RBP
              2: FlexColumnWidth(1.5), // Harga CBP
              3: FlexColumnWidth(1.5), // Harga Outlet
            },
            children: [
              // Header Tabel
              TableRow(
                children: [
                  _buildTableHeader('Product'),
                  _buildTableHeader('Harga RBP', alignment: TextAlign.right),
                  _buildTableHeader('Harga CBP', alignment: TextAlign.right),
                  _buildTableHeader('Harga Outlet', alignment: TextAlign.right),
                ],
              ),
              // Garis Pemisah
              TableRow(children: [
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
              ]),
              // Data Produk
              for (var product in section.items)
                TableRow(
                  children: [
                    _buildTableCell(product.productName),
                    _buildTableCell(product.hargaRbp, alignment: TextAlign.right),
                    _buildTableCell(product.hargaCbp, alignment: TextAlign.right),
                    _buildTableCell(product.hargaOutlet, alignment: TextAlign.right),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Tambah horizontal padding
      child: Text(text, textAlign: alignment, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 12)), // Font lebih kecil
    );
  }

  Widget _buildTableCell(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 4.0), // Tambah horizontal padding
      child: Text(text, textAlign: alignment, style: const TextStyle(color: Colors.black87, fontSize: 12)), // Font lebih kecil
    );
  }
}
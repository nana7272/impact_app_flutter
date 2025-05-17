// screens/activity/views/planogram_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/planogram_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';


class PlanogramTabView extends StatefulWidget {
  const PlanogramTabView({Key? key}) : super(key: key);

  @override
  State<PlanogramTabView> createState() => _PlanogramTabViewState();
}

class _PlanogramTabViewState extends State<PlanogramTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showEnlargedImage(BuildContext context, String imageUrl, String? caption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: caption != null ? Text(caption, style: const TextStyle(color: Colors.white, fontSize: 16)) : null,
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl), // Optional: untuk animasi hero
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
              provider.loadPlanogramReportData(forceRefresh: true);
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
    switch (provider.planogramDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Planogram."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.planogramErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadPlanogramReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.planogramReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Planogram untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.planogramReports.length,
          itemBuilder: (context, index) {
            final report = provider.planogramReports[index];
            return _buildPlanogramOutletCard(context, report, provider);
          },
        );
    }
  }

  Widget _buildPlanogramOutletCard(BuildContext context, PlanogramReport report, ActivityProvider provider) {
    // Format tanggal transaksi dari API (misal "2025-05-16")
    String displayTransactionDate = provider.formattedSelectedDateForHeaderCard; // Fallback
    try {
        // API: "2025-05-16"
        DateTime parsedApiDate = DateFormat("yyyy-MM-dd").parse(report.transactionDate);
        displayTransactionDate = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedApiDate); // Sesuai UI
    } catch (e) {
        print("Error parsing Planogram transaction date: ${report.transactionDate} - $e");
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
              color: Colors.grey[200], // Warna header outlet
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row( // Menggunakan Row untuk ikon dan teks
              children: [
                Icon(Icons.storefront_outlined, color: Colors.blue[700], size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.outletName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Daftar Dokumentasi Planogram
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.documentations.length,
            itemBuilder: (context, docIndex) {
              final doc = report.documentations[docIndex];
              return _buildDocumentationItem(context, doc);
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

  Widget _buildDocumentationItem(BuildContext context, Documentation doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Image (Planogram)
          if (doc.masterImageUrl.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Center( // Pusatkan gambar master
                   child: GestureDetector(
                    onTap: () => _showEnlargedImage(context, doc.masterImageUrl, "Master Planogram"),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: doc.masterImageUrl,
                        height: 150, // Tinggi gambar master
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                      ),
                    ),
                                   ),
                 ),
                const SizedBox(height: 10),
              ],
            ),

          _buildInfoRow("Display Type", doc.displayType),
          const Divider(height: 16),
          _buildInfoRow("Display Issue", doc.displayIssue),
          const Divider(height: 20),

          // Foto Before dan After
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPhotoColumn("Foto Before", doc.fotoBeforeUrl, doc.descGambarBefore, context)),
              const SizedBox(width: 16),
              Expanded(child: _buildPhotoColumn("Foto After", doc.fotoAfterUrl, doc.descGambarAfter, context)),
            ],
          ),
           //if (docIndex < Provider.of<ActivityProvider>(context, listen: false).planogramReports.firstWhere((r) => r.documentations.contains(doc)).documentations.length -1 )
          const Divider(thickness: 1, height: 30, color: Colors.black12), // Pemisah antar dokumentasi
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPhotoColumn(String title, String imageUrl, String? description, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showEnlargedImage(context, imageUrl, description ?? title),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 120, // Tinggi gambar before/after
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 120, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (context, url, error) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text("Desc Gambar", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(description ?? '-', style: const TextStyle(fontSize: 14, color: Colors.black87)),
         const SizedBox(height: 4),
        Container(height: 1, color: Colors.blueGrey[200]) // Garis bawah deskripsi
      ],
    );
  }
}
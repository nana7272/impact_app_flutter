// screens/activity/views/sampling_konsumen_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/sampling_konsumen_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';


class SamplingKonsumenTabView extends StatefulWidget {
  const SamplingKonsumenTabView({Key? key}) : super(key: key);

  @override
  State<SamplingKonsumenTabView> createState() => _SamplingKonsumenTabViewState();
}

class _SamplingKonsumenTabViewState extends State<SamplingKonsumenTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showEnlargedConsumerImage(BuildContext context, String? imageUrl, String consumerName) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Jika tidak ada gambar, bisa tampilkan pesan atau tidak lakukan apa-apa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada gambar untuk konsumen $consumerName')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(consumerName, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
              provider.loadSamplingKonsumenReportData(forceRefresh: true);
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
    switch (provider.samplingKonsumenDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Sampling Konsumen."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.samplingKonsumenErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadSamplingKonsumenReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.samplingKonsumenReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Sampling Konsumen untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.samplingKonsumenReports.length,
          itemBuilder: (context, index) {
            final report = provider.samplingKonsumenReports[index];
            return _buildSamplingOutletCard(context, report);
          },
        );
    }
  }

  Widget _buildSamplingOutletCard(BuildContext context, SamplingKonsumenReport report) {
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
            child: Text(
              report.outletName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Alamat Outlet
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
            child: Text(
              report.outletAddress,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Daftar Consumer Samplings
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.consumerSamplings.length,
            itemBuilder: (context, consumerIndex) {
              final consumer = report.consumerSamplings[consumerIndex];
              return _buildConsumerSamplingItem(context, consumer);
            },
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 12, endIndent: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerSamplingItem(BuildContext context, ConsumerSampling consumer) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consumer Image
              GestureDetector(
                onTap: () => _showEnlargedConsumerImage(context, consumer.consumerImageUrl, consumer.consumerName),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: consumer.consumerImageUrl != null && consumer.consumerImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(consumer.consumerImageUrl!)
                      : null, // No placeholder for CircleAvatar's backgroundImage
                  child: consumer.consumerImageUrl == null || consumer.consumerImageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Consumer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consumer.consumerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (consumer.consumerEmail != null && consumer.consumerEmail!.isNotEmpty)
                      Text("Email: ${consumer.consumerEmail!}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    Text("No.Hp: ${consumer.consumerPhone}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                     Text("Waktu Sampling: ${consumer.samplingTime}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tabel Produk yang Disampling
          Text("Produk Diberikan:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          const SizedBox(height: 4),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Product
              1: IntrinsicColumnWidth(), // Quantity (wrap content)
              2: FlexColumnWidth(2), // Keterangan
            },
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5, borderRadius: BorderRadius.circular(4)),
            children: [
              // Header Tabel Produk
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                children: [
                  _buildTableHeaderSmall('Product'),
                  _buildTableHeaderSmall('Qty', alignment: TextAlign.center),
                  _buildTableHeaderSmall('Keterangan'),
                ],
              ),
              // Data Produk
              for (var product in consumer.products)
                TableRow(
                  children: [
                    _buildTableCellSmall(product.productName),
                    _buildTableCellSmall(product.quantity.toString(), alignment: TextAlign.center),
                    _buildTableCellSmall(product.keteranganProduk ?? '-'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderSmall(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(text, textAlign: alignment, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 12)),
    );
  }

  Widget _buildTableCellSmall(String text, {TextAlign alignment = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(text, textAlign: alignment, style: const TextStyle(color: Colors.black87, fontSize: 12)),
    );
  }
}
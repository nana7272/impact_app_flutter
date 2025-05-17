// screens/activity/views/activation_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/activation_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Sudah diimpor di posm_tab_view

class ActivationTabView extends StatefulWidget {
  const ActivationTabView({Key? key}) : super(key: key);

  @override
  State<ActivationTabView> createState() => _ActivationTabViewState();
}

class _ActivationTabViewState extends State<ActivationTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showActivationImageDialog(BuildContext context, ActivationImageData imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: imageData.imageUrl,
                    fit: BoxFit.contain, // Contain agar gambar tidak terpotong di dialog
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogRow("Program:", imageData.program),
                _buildDialogRow("Periode:", imageData.periode),
                _buildDialogRow("Keterangan:", imageData.keterangan),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: const Text("Oke", style: TextStyle(color: Colors.blue, fontSize: 16)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
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
              provider.loadActivationReportData(forceRefresh: true);
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
    switch (provider.activationDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Aktivasi."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.activationErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadActivationReportData(forceRefresh: true),
        );
      case DataState.loaded:
        final activationReport = provider.activationReport;
        if (activationReport == null || activationReport.details.isEmpty && activationReport.summary.totalSudahAktivasi == 0 && activationReport.summary.totalBelumAktivasi == 0) {
          return const Center(child: Text('Tidak ada data Aktivasi untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return Column(
          children: [
            // Summary Cards
            _buildSummaryActivationSection(activationReport!.summary),
            const SizedBox(height: 16),
            // Details List
            Expanded(
              child: activationReport.details.isEmpty
                ? const Center(child: Text("Tidak ada detail Aktivasi yang dilaporkan."))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 70),
                    itemCount: activationReport.details.length,
                    itemBuilder: (context, index) {
                      final detail = activationReport.details[index];
                      return _buildActivationOutletCard(context, detail, provider);
                    },
                  ),
            ),
          ],
        );
    }
  }

  Widget _buildSummaryActivationSection(ActivationSummary summary) {
    return Row( // Sesuai UI, summary bersebelahan
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Total Sudah Aktivasi",
            count: summary.totalSudahAktivasi,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: "Total Belum Aktivasi",
            count: summary.totalBelumAktivasi,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required int count, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(count.toString(), style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationOutletCard(BuildContext context, ActivationDetail detail, ActivityProvider provider) {
    String displayDate = provider.formattedSelectedDateForActivationHeader;
    String displayTime = provider.formattedTimeForActivationHeader;

    try {
      if (detail.transactionDatetime.isNotEmpty) {
        // API: "2025-05-15 06:51:10"
        DateTime parsedDateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(detail.transactionDatetime);
        displayDate = DateFormat('yyyy-MM-dd').format(parsedDateTime); // UI: "2024-02-26"
        displayTime = DateFormat('HH:mm:ss').format(parsedDateTime); // UI: "20:03:00"
      }
    } catch (e) {
      print("Error parsing Activation transaction datetime: ${detail.transactionDatetime} - $e");
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Outlet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    detail.outletName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(displayDate, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    Text(displayTime, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            // Grid Gambar Aktivasi
            if (detail.imagesData.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: detail.imagesData.length,
                itemBuilder: (context, imageIndex) {
                  final imageData = detail.imagesData[imageIndex];
                  return GestureDetector(
                    onTap: () => _showActivationImageDialog(context, imageData),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: CachedNetworkImage(
                        imageUrl: imageData.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  );
                },
              )
            else
              const Text("Tidak ada gambar Aktivasi untuk outlet ini.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
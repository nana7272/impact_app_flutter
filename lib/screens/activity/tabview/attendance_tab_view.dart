// screens/activity/views/attendance_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/attendance_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart'; // Untuk DateSelectorWidget, dll.
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view_gallery.dart'; // Untuk galeri gambar di popup
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';


class AttendanceTabView extends StatefulWidget {
  // Hapus parameter visits jika tidak lagi menggunakan data dummy
  // const AttendanceTabView({Key? key, required this.visits}) : super(key: key);
  const AttendanceTabView({Key? key}) : super(key: key);

  @override
  State<AttendanceTabView> createState() => _AttendanceTabViewState();
}

class _AttendanceTabViewState extends State<AttendanceTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showVisitImagesDialog(BuildContext context, List<VisitImage> images, String outletName) {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada gambar kunjungan untuk ditampilkan.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container( // Tambahkan Container untuk membatasi tinggi Dialog
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7), // Batasi tinggi
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    "Dokumentasi Kunjungan: $outletName",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded( // Gunakan Expanded agar PhotoViewGallery bisa scroll jika kontennya banyak
                  child: PhotoViewGallery.builder(
                    itemCount: images.length,
                    builder: (context, index) {
                      final img = images[index];
                      return PhotoViewGalleryPageOptions(
                        imageProvider: CachedNetworkImageProvider(img.imageUrl),
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        heroAttributes: PhotoViewHeroAttributes(tag: img.imageUrl + index.toString()), // Tag unik
                        // Tambahkan builder untuk caption di bawah gambar jika perlu
                        // Contoh sederhana:
                        // child: Stack(
                        //   alignment: Alignment.bottomCenter,
                        //   children: [
                        //     Positioned(
                        //       bottom: 0,
                        //       child: Container(
                        //         padding: EdgeInsets.all(8),
                        //         color: Colors.black.withOpacity(0.5),
                        //         child: Text(
                        //           "${img.keteranganGambar} (${img.timeGambar})",
                        //           style: TextStyle(color: Colors.white, fontSize: 12),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      );
                    },
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration: const BoxDecoration(color: Colors.black54), // Latar belakang galeri
                    pageController: PageController(), // Controller untuk galeri
                    loadingBuilder: (context, event) => const Center(
                      child: SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    child: const Text("Tutup", style: TextStyle(color: Colors.blue, fontSize: 16)),
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
              provider.loadAttendanceReportData(forceRefresh: true);
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
    switch (provider.attendanceDataState) {
      case DataState.initial:
         // Data sudah diload di initState provider, jadi loading akan muncul jika belum selesai
        return const LoadingIndicator();
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.attendanceErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadAttendanceReportData(forceRefresh: true),
        );
      case DataState.loaded:
        final attendanceReport = provider.attendanceReport;
        if (attendanceReport == null || (attendanceReport.details.isEmpty && attendanceReport.summary.plan == 0)) {
          return const Center(child: Text('Tidak ada data Absensi untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return Column(
          children: [
            _buildAttendanceSummarySection(attendanceReport.summary),
            const SizedBox(height: 16),
            Expanded(
              child: attendanceReport.details.isEmpty
                  ? const Center(child: Text("Belum ada kunjungan tercatat."))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 70),
                      itemCount: attendanceReport.details.length,
                      itemBuilder: (context, index) {
                        final detail = attendanceReport.details[index];
                        return _buildAttendanceDetailItem(context, detail);
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                    ),
            ),
          ],
        );
    }
  }

  Widget _buildAttendanceSummarySection(AttendanceSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(title: "Plan", count: summary.plan, color: Colors.amber.shade600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(title: "Dikunjungi", count: summary.dikunjungi, color: Colors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(title: "Tidak Dikunjungi", count: summary.tidakDikunjungi, color: Colors.red),
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

  Widget _buildAttendanceDetailItem(BuildContext context, AttendanceDetail detail) {
     // Format tanggal dari "2025-05-17" menjadi "17 May 2025"
    String formattedDate = detail.tanggal;
    try {
        DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(detail.tanggal);
        formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(parsedDate);
    } catch(e) {
        print("Error parsing attendance detail date: ${detail.tanggal} - $e");
    }

    return ListTile(
      leading: CircleAvatar( // Ikon toko
        backgroundColor: Colors.blue[100],
        child: Icon(Icons.storefront_outlined, color: Colors.blue[700]),
      ),
      title: Text(detail.outletName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggal: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text('Jam Check In: ${detail.jamCheckIn}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (detail.jamCheckOut != null)
            Text('Jam Check Out: ${detail.jamCheckOut}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (detail.durasi != null)
            Text('Durasi: ${detail.durasi}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
      trailing: Text(
        detail.displayDatetime.split(',').last.trim(), // Ambil bagian waktu dari "17 May, 10:32:53"
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: () {
        _showVisitImagesDialog(context, detail.visitImages, detail.outletName);
      },
    );
  }
}
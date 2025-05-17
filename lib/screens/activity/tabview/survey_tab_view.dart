// screens/activity/views/survey_tab_view.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/model/survey_report.dart';
import 'package:impact_app/screens/activity/provider/activity_provider.dart';
import 'package:impact_app/screens/activity/widget/common_activity_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class SurveyTabView extends StatefulWidget {
  const SurveyTabView({Key? key}) : super(key: key);

  @override
  State<SurveyTabView> createState() => _SurveyTabViewState();
}

class _SurveyTabViewState extends State<SurveyTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Untuk mengelompokkan jawaban checkbox berdasarkan pertanyaan
  Map<String, List<String>> _groupCheckboxAnswers(List<QuestionAndAnswer> qas) {
    final Map<String, List<String>> grouped = {};
    for (var qa in qas) {
      if (qa.questionType == "checkbox") {
        if (!grouped.containsKey(qa.questionText)) {
          grouped[qa.questionText] = [];
        }
        grouped[qa.questionText]!.add(qa.answerText);
      }
    }
    return grouped;
  }

  void _showEnlargedSurveyImage(BuildContext context, String imageUrl, String question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(question, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
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
              provider.loadSurveyReportData(forceRefresh: true);
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
    switch (provider.surveyDataState) {
      case DataState.initial:
        return const Center(child: Text("Pilih tanggal untuk memuat data Survey."));
      case DataState.loading:
        return const LoadingIndicator();
      case DataState.error:
        return ErrorMessageWidget(
          message: provider.surveyErrorMessage ?? "Terjadi kesalahan",
          onRetry: () => provider.loadSurveyReportData(forceRefresh: true),
        );
      case DataState.loaded:
        if (provider.surveyReports.isEmpty) {
          return const Center(child: Text('Tidak ada data Survey untuk tanggal ini.', style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 70),
          itemCount: provider.surveyReports.length,
          itemBuilder: (context, index) {
            final report = provider.surveyReports[index];
            return _buildSurveyOutletCard(context, report, provider);
          },
        );
    }
  }

  Widget _buildSurveyOutletCard(BuildContext context, SurveyReport report, ActivityProvider provider) {
     String displayTransactionDate = provider.formattedSelectedDateForHeaderCard; // Fallback
    try {
        // API: "2025-05-17"
        DateTime parsedApiDate = DateFormat("yyyy-MM-dd").parse(report.transactionDate);
        displayTransactionDate = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedApiDate); // Sesuai UI outlet header: 2024-02-26
    } catch (e) {
        print("Error parsing Survey transaction date: ${report.transactionDate} - $e");
    }

    // Proses pengelompokan jawaban checkbox
    final groupedCheckboxAnswers = _groupCheckboxAnswers(report.questionsAndAnswers);
    final List<Widget> surveyItems = [];
    final Set<String> processedCheckboxQuestions = {}; // Untuk menandai pertanyaan checkbox yang sudah diproses

    int qaIndex = 0;
    for (var qa in report.questionsAndAnswers) {
      qaIndex++;
      if (qa.questionType == "checkbox") {
        if (!processedCheckboxQuestions.contains(qa.questionText)) {
          surveyItems.add(_buildSurveyQuestionItem(
            context,
            "${surveyItems.length + 1}. ${qa.questionText}", // Nomor pertanyaan
            groupedCheckboxAnswers[qa.questionText]!.join(', '), // Gabungkan jawaban checkbox
            qa.questionType,
          ));
          processedCheckboxQuestions.add(qa.questionText);
        }
      } else {
        surveyItems.add(_buildSurveyQuestionItem(
          context,
          "${surveyItems.length + 1}. ${qa.questionText}", // Nomor pertanyaan
          qa.answerText,
          qa.questionType,
        ));
      }
    }


    return Card(
      elevation: 1, // Lebih soft dari UI
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Border radius lebih kecil
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Outlet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white, // Sesuai UI, header outlet putih
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              // borderRadius: const BorderRadius.only(
              //   topLeft: Radius.circular(8),
              //   topRight: Radius.circular(8),
              // ),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, color: Colors.grey[700], size: 28), // Ikon lebih besar dan abu2
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                        report.outletName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        displayTransactionDate, // Menggunakan tanggal yang sudah diformat
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                )
              ],
            ),
          ),
          // Daftar Pertanyaan dan Jawaban
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: surveyItems,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSurveyQuestionItem(BuildContext context, String question, String answer, String type) {
    bool isImage = type == "documentasi";
    bool isCheckboxOrRadio = type == "checkbox" || type == "radio"; // Sesuai UI, radio juga mirip input text

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          const SizedBox(height: 6),
          isImage
              ? GestureDetector(
                  onTap: () => _showEnlargedSurveyImage(context, answer, question),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: answer,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (context, url, error) => Container(height: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    answer,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
        ],
      ),
    );
  }
}
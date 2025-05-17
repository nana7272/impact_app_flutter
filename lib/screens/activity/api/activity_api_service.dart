// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/screens/activity/model/activation_report.dart';
import 'package:impact_app/screens/activity/model/attendance_report.dart';
import 'package:impact_app/screens/activity/model/competitor_report.dart';
import 'package:impact_app/screens/activity/model/oos_report.dart';
import 'package:impact_app/screens/activity/model/open_ending_report.dart';
import 'package:impact_app/screens/activity/model/planogram_report.dart';
import 'package:impact_app/screens/activity/model/posm_report.dart';
import 'package:impact_app/screens/activity/model/price_monitoring_report.dart';
import 'package:impact_app/screens/activity/model/sales_report.dart';
import 'package:impact_app/screens/activity/model/sampling_konsumen_report.dart';
import 'package:impact_app/screens/activity/model/stock_report.dart';
import 'package:impact_app/screens/activity/model/survey_report.dart'; // Sesuaikan path jika berbeda

class ActivityApiService {

  Future<List<SalesReport>> fetchSalesData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/report/sales?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      // Jika server mengembalikan respons 200 OK,
      // parse JSON.
      return salesReportFromJson(response.body);
    } else {
      // Jika server tidak mengembalikan respons 200 OK,
      // lempar sebuah exception.
      return [];
    }
  }

  // Method baru untuk mengambil data stok (Availability)
  Future<StockReport?> fetchStockReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseApiUrl}/api/report/stock?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      return stockReportFromJson(response.body);
    } else {
      // Pertimbangkan untuk throw Exception
      // throw Exception('Failed to load stock report data: ${response.statusCode}');
      print('Failed to load stock report data: ${response.statusCode}');
      return null; // Atau throw exception
    }
  }

  // Method baru untuk mengambil data Open Ending
  Future<List<OpenEndingReport>> fetchOpenEndingReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/open-ending?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      return openEndingReportFromJson(response.body);
    } else {
      print('Failed to load open ending report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Open Ending: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data POSM
  Future<PosmReport?> fetchPosmReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/posm?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null; // Handle jika body kosong tapi status 200
      return posmReportFromJson(response.body);
    } else {
      print('Failed to load POSM report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data POSM: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data OOS
  Future<List<OosReport>> fetchOosReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/oos?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return []; // Handle jika body kosong atau array kosong
      return oosReportFromJson(response.body);
    } else {
      print('Failed to load OOS report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data OOS: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Price Monitoring
  Future<List<PriceMonitoringReport>> fetchPriceMonitoringReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/pricemonitoring?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return []; // Handle jika body kosong atau array kosong
      return priceMonitoringReportFromJson(response.body);
    } else {
      print('Failed to load Price Monitoring report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Price Monitoring: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Activation
  Future<ActivationReport?> fetchActivationReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/activation?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null; // Handle jika body kosong tapi status 200
      return activationReportFromJson(response.body);
    } else {
      print('Failed to load Activation report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Activation: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Planogram
  Future<List<PlanogramReport>> fetchPlanogramReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/planogram?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return []; // Handle jika body kosong atau array kosong
      return planogramReportFromJson(response.body);
    } else {
      print('Failed to load Planogram report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Planogram: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Sampling Konsumen
  Future<List<SamplingKonsumenReport>> fetchSamplingKonsumenReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/samplingkonsumen?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return []; // Handle jika body kosong atau array kosong
      return samplingKonsumenReportFromJson(response.body);
    } else {
      print('Failed to load Sampling Konsumen report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Sampling Konsumen: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Survey
  Future<List<SurveyReport>> fetchSurveyReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/survey?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return []; // Handle jika body kosong atau array kosong
      return surveyReportFromJson(response.body);
    } else {
      print('Failed to load Survey report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Survey: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Attendance (Absen)
  Future<AttendanceReport?> fetchAttendanceReportData(String tanggal, String idUser) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseApiUrl}/api/report/absen?tanggal=$tanggal&id_user=$idUser'));

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null; // Handle jika body kosong tapi status 200
      return attendanceReportFromJson(response.body);
    } else {
      print('Failed to load Attendance report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Attendance: ${response.statusCode}');
    }
  }

  // Method baru untuk mengambil data Competitor
  Future<List<CompetitorReport>> fetchCompetitorReportData(String tanggal, String idUser) async {
    // GANTI URL INI DENGAN ENDPOINT YANG BENAR UNTUK COMPETITOR DATA
    final String apiUrl = '${ApiConstants.baseApiUrl}/api/report/promoactivity?tanggal=$tanggal&id_user=$idUser';
    // Contoh di atas menggunakan /competitor, sesuaikan jika berbeda. API response yang Anda berikan akan saya gunakan.

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == "[]") return [];
      return competitorReportFromJson(response.body);
    } else {
      print('Failed to load Competitor report data: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal memuat data Competitor: ${response.statusCode}');
    }
  }
}
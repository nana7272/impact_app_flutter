// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:impact_app/api/api_constants.dart';
import 'package:impact_app/screens/activity/model/sales_report.dart'; // Sesuaikan path jika berbeda

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
}
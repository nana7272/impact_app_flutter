// screens/activity/provider/activity_provider.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/api/activity_api_service.dart';
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
import 'package:impact_app/screens/activity/model/survey_report.dart';
// ... (import model lainnya)
import 'package:impact_app/utils/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

enum DataState { initial, loading, loaded, error }

class ActivityProvider with ChangeNotifier {
  final ActivityApiService _apiService = ActivityApiService();

  String? _userId;

  // Common State
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Attendance Tab State
  DataState _attendanceDataState = DataState.initial;
  DataState get attendanceDataState => _attendanceDataState;
  AttendanceReport? _attendanceReport;
  AttendanceReport? get attendanceReport => _attendanceReport;
  String? _attendanceErrorMessage;
  String? get attendanceErrorMessage => _attendanceErrorMessage;

  // ... (State untuk tab-tab lainnya) ...
  // SPO Tab State
  DataState _spoDataState = DataState.initial;
  DataState get spoDataState => _spoDataState;
  List<SalesReport> _salesReports = [];
  List<SalesReport> get salesReports => _salesReports;
  String? _spoErrorMessage;
  String? get spoErrorMessage => _spoErrorMessage;

  // Availability Tab State
  DataState _availabilityDataState = DataState.initial;
  DataState get availabilityDataState => _availabilityDataState;
  StockReport? _stockReport;
  StockReport? get stockReport => _stockReport;
  String? _availabilityErrorMessage;
  String? get availabilityErrorMessage => _availabilityErrorMessage;

  // Open Ending Tab State
  DataState _openEndingDataState = DataState.initial;
  DataState get openEndingDataState => _openEndingDataState;
  List<OpenEndingReport> _openEndingReports = [];
  List<OpenEndingReport> get openEndingReports => _openEndingReports;
  String? _openEndingErrorMessage;
  String? get openEndingErrorMessage => _openEndingErrorMessage;

  // POSM Tab State
  DataState _posmDataState = DataState.initial;
  DataState get posmDataState => _posmDataState;
  PosmReport? _posmReport;
  PosmReport? get posmReport => _posmReport;
  String? _posmErrorMessage;
  String? get posmErrorMessage => _posmErrorMessage;

  // OOS Tab State
  DataState _oosDataState = DataState.initial;
  DataState get oosDataState => _oosDataState;
  List<OosReport> _oosReports = [];
  List<OosReport> get oosReports => _oosReports;
  String? _oosErrorMessage;
  String? get oosErrorMessage => _oosErrorMessage;

  // Price Monitoring Tab State
  DataState _priceMonitoringDataState = DataState.initial;
  DataState get priceMonitoringDataState => _priceMonitoringDataState;
  List<PriceMonitoringReport> _priceMonitoringReports = [];
  List<PriceMonitoringReport> get priceMonitoringReports => _priceMonitoringReports;
  String? _priceMonitoringErrorMessage;
  String? get priceMonitoringErrorMessage => _priceMonitoringErrorMessage;

  // Activation Tab State
  DataState _activationDataState = DataState.initial;
  DataState get activationDataState => _activationDataState;
  ActivationReport? _activationReport;
  ActivationReport? get activationReport => _activationReport;
  String? _activationErrorMessage;
  String? get activationErrorMessage => _activationErrorMessage;

  // Planogram Tab State
  DataState _planogramDataState = DataState.initial;
  DataState get planogramDataState => _planogramDataState;
  List<PlanogramReport> _planogramReports = [];
  List<PlanogramReport> get planogramReports => _planogramReports;
  String? _planogramErrorMessage;
  String? get planogramErrorMessage => _planogramErrorMessage;

  // Sampling Konsumen Tab State
  DataState _samplingKonsumenDataState = DataState.initial;
  DataState get samplingKonsumenDataState => _samplingKonsumenDataState;
  List<SamplingKonsumenReport> _samplingKonsumenReports = [];
  List<SamplingKonsumenReport> get samplingKonsumenReports => _samplingKonsumenReports;
  String? _samplingKonsumenErrorMessage;
  String? get samplingKonsumenErrorMessage => _samplingKonsumenErrorMessage;

  // Survey Tab State
  DataState _surveyDataState = DataState.initial;
  DataState get surveyDataState => _surveyDataState;
  List<SurveyReport> _surveyReports = [];
  List<SurveyReport> get surveyReports => _surveyReports;
  String? _surveyErrorMessage;
  String? get surveyErrorMessage => _surveyErrorMessage;

  // Competitor Tab State (menggantikan POSM jika POSM tidak lagi menjadi tab 'Competitor')
  DataState _competitorDataState = DataState.initial;
  DataState get competitorDataState => _competitorDataState;
  List<CompetitorReport> _competitorReports = [];
  List<CompetitorReport> get competitorReports => _competitorReports;
  String? _competitorErrorMessage;
  String? get competitorErrorMessage => _competitorErrorMessage;


  ActivityProvider() {
    // Panggil _initializeUserAndLoadInitialData tanpa await di constructor
    // dan biarkan method tersebut yang menangani notifikasi setelah selesai
    _initializeUserAndLoadInitialData();
  }

  Future<void> _initializeUserAndLoadInitialData() async {
    final user = await SessionManager().getCurrentUser();
    _userId = user?.idLogin;
    // Penting: Jangan panggil notifyListeners() secara langsung di sini jika itu
    // adalah bagian dari inisialisasi state yang akan langsung digunakan oleh UI
    // saat provider pertama kali dibuat.
    // Pemuatan data awal (misalnya untuk Attendance) sebaiknya dipanggil dari initState
    // widget yang menggunakan provider, atau setelah frame pertama selesai.

    // Namun, jika _userId adalah satu-satunya yang diinisialisasi di sini dan
    // tidak ada notifyListeners() langsung, maka tidak masalah.
    // Pemanggilan loadAttendanceReportData() akan dipindahkan ke _ActivityScreenContentState.initState()
    // atau ke listener TabController saat tab pertama aktif.
  }

  String get formattedSelectedDateForApi {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }
  // ... (getter format tanggal lainnya tetap sama) ...
   String get formattedSelectedDateForDisplay {
     return DateFormat('dd MMMM yy', 'id_ID').format(_selectedDate);
  }

  String get formattedSelectedDateForPosmHeader {
     return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  String get formattedTimeForPosmHeader {
     return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  String get formattedSelectedDateForHeaderCard {
      return DateFormat('dd MMMM yy', 'id_ID').format(_selectedDate);
  }

  String get formattedSelectedDateForActivationHeader {
     return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  String get formattedTimeForActivationHeader {
     return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  Future<void> updateSelectedDate(DateTime newDate) async {
    if (newDate != _selectedDate) {
      _selectedDate = newDate;
      notifyListeners();
      // Setelah tanggal berubah, panggil method untuk reload data tab yang aktif
      // Ini akan ditangani oleh listener di ActivityScreen atau pemanggilan eksplisit dari tab view
    }
  }

  // Modifikasi pada method load data:
  // Hapus pemanggilan notifyListeners() yang tidak perlu di awal method jika tidak ada perubahan state yang signifikan
  // sebelum proses async dimulai. Cukup panggil di akhir atau saat state benar-benar berubah.

  Future<void> loadAttendanceReportData({bool forceRefresh = false}) async {

    final user = await SessionManager().getCurrentUser();
    _userId = user?.idLogin;

    if (_userId == null || _userId!.isEmpty) {
      _attendanceDataState = DataState.error;
      _attendanceErrorMessage = "User ID tidak ditemukan.";
      notifyListeners();
      return;
    }
    // Hanya set loading jika memang belum loading atau jika dipaksa refresh
    if (_attendanceDataState == DataState.loading && !forceRefresh) return;

    _attendanceDataState = DataState.loading;
    // Hanya panggil notifyListeners() jika state benar-benar berubah dan ini bukan pemanggilan dari constructor
    // Jika dipanggil dari initState widget, lebih aman menundanya.
    // Untuk mengatasi '!_dirty', kita pastikan ini tidak dipanggil saat build.
    // Solusi yang lebih aman adalah memanggil notifyListeners() hanya setelah operasi async.
    // Jika ini adalah pemanggilan awal dari initState, tidak perlu notify loading di sini,
    // UI akan menampilkan loading berdasarkan _attendanceDataState.initial atau pemanggilan
    // notifyListeners() setelah Future.microtask.
    // Namun, untuk loading yang terlihat, notify di sini penting.
    // Kita akan memastikan ini tidak dipanggil saat build.
    if (WidgetsBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
       // Jika dipanggil di luar proses build/layout, aman untuk notify.
       // Tapi untuk kasus init, lebih baik menunda atau memastikan.
    }
     // Cara aman untuk update UI setelah frame:
    // Future.microtask(() {
    //   if(_attendanceDataState == DataState.loading) notifyListeners();
    // });
    // Atau, jika method ini dipanggil setelah widget tree stabil (misal, dari user action atau tab change)
    // maka notifyListeners() di sini untuk state loading aman.
    notifyListeners(); // Panggil di sini agar UI update ke loading state


    try {
      _attendanceReport = await _apiService.fetchAttendanceReportData(formattedSelectedDateForApi, _userId!);
      _attendanceDataState = DataState.loaded;
      _attendanceErrorMessage = null;
    } catch (e) {
      _attendanceDataState = DataState.error;
      _attendanceErrorMessage = e.toString();
      _attendanceReport = null;
      print("Error fetching Attendance report data: $e");
    }
    notifyListeners();
  }

  // Lakukan hal serupa untuk semua method load data lainnya:
  // Pastikan notifyListeners() untuk state loading dipanggil dengan hati-hati,
  // terutama jika ada kemungkinan dipanggil selama fase build awal.
  // Panggilan notifyListeners() di akhir (setelah try-catch) biasanya aman.

  Future<void> loadSalesData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_spoDataState == DataState.loading && !forceRefresh) return;
    _spoDataState = DataState.loading;
    notifyListeners(); // Untuk loading state
    try {
      _salesReports = await _apiService.fetchSalesData(formattedSelectedDateForApi, _userId!);
      _spoDataState = DataState.loaded;
      _spoErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _salesReports = []; }
    notifyListeners();
  }
  // ... (dan seterusnya untuk semua method load lainnya) ...
  Future<void> loadStockReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_availabilityDataState == DataState.loading && !forceRefresh) return;
    _availabilityDataState = DataState.loading;
    notifyListeners();
    try {
      _stockReport = await _apiService.fetchStockReportData(formattedSelectedDateForApi, _userId!);
      _availabilityDataState = DataState.loaded;
      _availabilityErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _stockReport = null; }
    notifyListeners();
  }

  Future<void> loadOpenEndingReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_openEndingDataState == DataState.loading && !forceRefresh) return;
    _openEndingDataState = DataState.loading;
    notifyListeners();
    try {
      _openEndingReports = await _apiService.fetchOpenEndingReportData(formattedSelectedDateForApi, _userId!);
      _openEndingDataState = DataState.loaded;
      _openEndingErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _openEndingReports = []; }
    notifyListeners();
  }

  Future<void> loadPosmReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_posmDataState == DataState.loading && !forceRefresh) return;
    _posmDataState = DataState.loading;
    notifyListeners();
    try {
      _posmReport = await _apiService.fetchPosmReportData(formattedSelectedDateForApi, _userId!);
      _posmDataState = DataState.loaded;
      _posmErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _posmReport = null; }
    notifyListeners();
  }

  Future<void> loadOosReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_oosDataState == DataState.loading && !forceRefresh) return;
    _oosDataState = DataState.loading;
    notifyListeners();
    try {
      _oosReports = await _apiService.fetchOosReportData(formattedSelectedDateForApi, _userId!);
      _oosDataState = DataState.loaded;
      _oosErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _oosReports = []; }
    notifyListeners();
  }
  Future<void> loadPriceMonitoringReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_priceMonitoringDataState == DataState.loading && !forceRefresh) return;
    _priceMonitoringDataState = DataState.loading;
    notifyListeners();
    try {
      _priceMonitoringReports = await _apiService.fetchPriceMonitoringReportData(formattedSelectedDateForApi, _userId!);
      _priceMonitoringDataState = DataState.loaded;
      _priceMonitoringErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _priceMonitoringReports = []; }
    notifyListeners();
  }
  Future<void> loadActivationReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_activationDataState == DataState.loading && !forceRefresh) return;
    _activationDataState = DataState.loading;
    notifyListeners();
    try {
      _activationReport = await _apiService.fetchActivationReportData(formattedSelectedDateForApi, _userId!);
      _activationDataState = DataState.loaded;
      _activationErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _activationReport = null; }
    notifyListeners();
  }
  Future<void> loadPlanogramReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_planogramDataState == DataState.loading && !forceRefresh) return;
    _planogramDataState = DataState.loading;
    notifyListeners();
    try {
      _planogramReports = await _apiService.fetchPlanogramReportData(formattedSelectedDateForApi, _userId!);
      _planogramDataState = DataState.loaded;
      _planogramErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _planogramReports = []; }
    notifyListeners();
  }
  Future<void> loadSamplingKonsumenReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_samplingKonsumenDataState == DataState.loading && !forceRefresh) return;
    _samplingKonsumenDataState = DataState.loading;
    notifyListeners();
    try {
      _samplingKonsumenReports = await _apiService.fetchSamplingKonsumenReportData(formattedSelectedDateForApi, _userId!);
      _samplingKonsumenDataState = DataState.loaded;
      _samplingKonsumenErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _samplingKonsumenReports = []; }
    notifyListeners();
  }

  Future<void> loadSurveyReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) { /* ... error handling ... */ notifyListeners(); return; }
    if (_surveyDataState == DataState.loading && !forceRefresh) return;
    _surveyDataState = DataState.loading;
    notifyListeners();
    try {
      _surveyReports = await _apiService.fetchSurveyReportData(formattedSelectedDateForApi, _userId!);
      _surveyDataState = DataState.loaded;
      _surveyErrorMessage = null;
    } catch (e) { /* ... error handling ... */ _surveyReports = []; }
    notifyListeners();
  }

  Future<void> loadCompetitorReportData({bool forceRefresh = false}) async {
    if (_userId == null || _userId!.isEmpty) {
      _competitorDataState = DataState.error;
      _competitorErrorMessage = "User ID tidak ditemukan.";
      notifyListeners();
      return;
    }
    if (_competitorDataState == DataState.loading && !forceRefresh) return;

    _competitorDataState = DataState.loading;
    notifyListeners();

    try {
      _competitorReports = await _apiService.fetchCompetitorReportData(formattedSelectedDateForApi, _userId!);
      _competitorDataState = DataState.loaded;
      _competitorErrorMessage = null;
    } catch (e) {
      _competitorDataState = DataState.error;
      _competitorErrorMessage = e.toString();
      _competitorReports = [];
      print("Error fetching Competitor report data: $e");
    }
    notifyListeners();
  }
}
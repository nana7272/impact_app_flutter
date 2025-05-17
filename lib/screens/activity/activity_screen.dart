// activity_screen.dart
import 'package:flutter/material.dart';
import 'package:impact_app/screens/activity/api/activity_api_service.dart';
import 'package:impact_app/screens/activity/model/sales_report.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan angka

import 'package:impact_app/screens/checkin/checin_screen.dart'; // Pastikan screen ini ada
import 'package:impact_app/utils/bottom_menu_handler.dart'; // Pastikan util ini ada
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart'; // Pastikan widget ini ada
import 'package:impact_app/widget/status_card_widget.dart'; // Pastikan widget ini ada

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Index untuk BottomNavigationBar, sesuaikan jika Activity bukan index ke-1
  final ActivityApiService _apiService = ActivityApiService();
  Future<List<SalesReport>>? _salesReportFuture;
  DateTime _selectedDate = DateTime.now(); // Default ke hari ini

  // GANTI INI: Anda harus mendapatkan id_user secara dinamis, misalnya dari shared preferences atau state management
  final String _idUser = "5";

  // Data dummy untuk tab Attendance, Anda bisa menggantinya dengan data asli
  final List<Map<String, String>> _dummyVisits = List.generate(
    4,
    (index) => {
      'store': 'TK ${index % 2 == 0 ? "SRI BUANA" : "MAJU JAYA"}',
      'date': '2024-02-${20 + index}',
      'checkIn': '10:1${index}:00',
      'checkOut': '11:2${index}:00',
      'duration': '01:10:00',
      'timestamp': '${20 + index} Feb, 10:1${index}'
    },
  );

  @override
  void initState() {
    super.initState();
    // Sesuaikan jumlah tab dengan UI (Attendance, SPO, Competitor, Availability, Open End)
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Bisa digunakan untuk logic tambahan saat tab berganti
        setState(() {}); // Memastikan UI di-rebuild untuk indikator tab
      }
      // Muat data hanya ketika tab SPO dipilih
      if (_tabController.index == 1) { // Index 1 adalah tab SPO
        _loadSalesData();
      }
    });
    // Muat data SPO jika tab SPO adalah tab awal (misalnya, jika _tabController.initialIndex = 1)
    // atau jika Anda ingin memuatnya secara default saat layar dibuka
    if (_tabController.index == 1) {
        _loadSalesData();
    }
  }

  void _loadSalesData() {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _salesReportFuture = _apiService.fetchSalesData(formattedDate, _idUser);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101), // Bisa disesuaikan
      builder: (BuildContext context, Widget? child) { // Styling DatePicker (opsional)
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Warna header
              onPrimary: Colors.white, // Warna teks di header
              onSurface: Colors.black, // Warna teks tanggal
            ),
            dialogBackgroundColor:Colors.white,
          ),
          child: child!,
        );
      }
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Muat ulang data hanya jika tab SPO aktif
        if (_tabController.index == 1) {
          _loadSalesData();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Latar belakang umum seperti UI
      appBar: AppBar(
        backgroundColor: Colors.white, // Sesuai UI
        elevation: 1, // Sedikit shadow
        title: const Text('Activity History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[700],
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue[700], // Warna indikator tab aktif
          ),
          tabs: [ // Menggunakan Padding untuk membuat tab terlihat seperti tombol
            _buildTab('Attandence'),
            _buildTab('SPO'),
            _buildTab('Competitor'),
            _buildTab('Availability'),
            _buildTab('Open End'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(_dummyVisits),
          _buildSPOTab(),
          _buildCompetitorTab(),
          _buildPlaceholderTab('Availability'), // Placeholder
          _buildPlaceholderTab('Open End'),   // Placeholder
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const CheckinMapScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.location_on, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTabSelected: (i) {
            // Panggil handler dari BottomMenu, dan juga update _selectedIndex jika perlu untuk UI di sini
            BottomMenu.onItemTapped(context, i);
            // setState(() { _selectedIndex = i; }); // Jika CustomBottomNavbar tidak menangani state highlight sendiri
        },
        onCheckInPressed: () {
          // Aksi yang sama dengan FAB utama, jika diperlukan
           Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const CheckinMapScreen()));
        },
      ),
    );
  }

  Widget _buildTab(String text) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // Warna latar belakang diatur oleh TabBar indicator dan unselectedLabelColor
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAttendanceTab(List<Map<String, String>> visits) {
    // Implementasi tab Attendance yang sudah ada atau yang baru
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Search here',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          // Status Cards (jika masih relevan dengan desain final Attendance)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatusCardWidget(
                title: "Plan",
                count: 20,
                color: Colors.yellow[700]!,
                textColor: Colors.black,
              ),
              StatusCardWidget(
                title: "Dikunjungi",
                count: 10,
                color: Colors.green,
                textColor: Colors.white,
              ),
              StatusCardWidget(
                title: "Tidak Dikunjungi",
                count: 10,
                color: Colors.red,
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Daftar Kunjungan
          Expanded(
            child: ListView.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.store, color: Colors.blue),
                    ),
                    title: Text(visit['store']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal: ${visit['date']}'),
                        Text('Check in: ${visit['checkIn']}'),
                        Text('Check out: ${visit['checkOut']}'),
                        Text('Durasi: ${visit['duration']}'),
                      ],
                    ),
                    trailing: Text(visit['timestamp']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSPOTab() {
    String formattedDateForDisplay = DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate); // Format Indonesia
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Mengurangi padding bawah
      child: Column(
        children: [
          // Baris untuk memilih tanggal
          Material( // Bungkus dengan Material untuk efek InkWell yang benar
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDateForDisplay, // Menampilkan tanggal yang dipilih
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ),
                    const Icon(Icons.search, color: Colors.blue, size: 24),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SalesReport>>(
              future: _salesReportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Tambahkan tombol Retry
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Coba Lagi"),
                          onPressed: _loadSalesData,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        )
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada data SPO untuk tanggal ini.', style: TextStyle(fontSize: 16)));
                }

                List<SalesReport> reports = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 70), // Padding untuk FAB
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    // Format tanggal dari API (misal "14 May 2025") ke format UI (misal "03 March 2024")
                    // Jika API sudah memberikan format "dd MMMM yyyy", maka tidak perlu parsing ulang
                    String displayTransactionDate = report.transactionDate;
                    try {
                      // Coba parse jika formatnya diketahui (misal "dd MMMM yyyy" dari API)
                      // dan format ulang jika perlu. Untuk contoh ini, kita asumsikan API sudah benar.
                       DateTime parsedDate = DateFormat("d MMMM yyyy", "en_US").parse(report.transactionDate);
                       displayTransactionDate = DateFormat("dd MMMM yyyy", "id_ID").format(parsedDate);
                    } catch (e) {
                      // Jika gagal parse, tampilkan apa adanya
                      print("Error parsing transaction date: ${report.transactionDate} - $e");
                    }


                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue[600], // Warna biru header kartu
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_outlined, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    report.outletName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                             padding: const EdgeInsets.only(left: 16.0, top: 6, bottom: 8),
                             child: Text(
                               displayTransactionDate, // Tanggal transaksi di bawah nama outlet
                               style: TextStyle(
                                 fontSize: 13,
                                 color: Colors.grey[700],
                                 fontWeight: FontWeight.w500
                               ),
                             ),
                           ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.5), // Product
                                1: FlexColumnWidth(1.2), // Quantity (agar center)
                                2: FlexColumnWidth(1.5), // Value (agar right)
                              },
                              children: [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Value', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13)),
                                    ),
                                  ],
                                ),
                                TableRow( // Garis pemisah
                                  children: [
                                    Divider(color: Colors.grey[300], height: 1, thickness: 1),
                                    Divider(color: Colors.grey[300], height: 1, thickness: 1),
                                    Divider(color: Colors.grey[300], height: 1, thickness: 1),
                                  ]
                                ),
                                for (var product in report.products)
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                                        child: Text(product.productName, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                                        child: Text(product.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                                        child: Text(
                                          NumberFormat("#,##0", "id_ID").format(product.value),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(color: Colors.black87, fontSize: 13)
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
                            child: Row(
                              children: [
                                Text(
                                  'Motorist: ',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                                Expanded( // Agar nama motorist bisa panjang
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorTab() {
    return _buildPlaceholderTab("Competitor");
  }

  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '$tabName Data Akan Ditampilkan Disini',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
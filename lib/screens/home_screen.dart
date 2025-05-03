import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/screens/pending_screen.dart';
import 'package:impact_app/screens/presentation_screen.dart';
import 'package:impact_app/screens/product_list_screen.dart';
import 'package:impact_app/screens/sales_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';
import 'package:impact_app/widget/header_home_widget.dart';
import 'package:impact_app/widget/rank_home_widget.dart';
import 'package:impact_app/widget/sales_line_chart.dart';
import 'package:impact_app/widget/target_widget.dart';
import 'package:impact_app/widget/visiting_bar_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<Map<String, dynamic>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('userData');
    return userData != null ? json.decode(userData) : {};
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user data found'));
          }
          final user = snapshot.data!;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  HeaderHomedWidget(
                    greeting: "Selamat Pagi,",
                    name: "Test",
                    role: "SPG",
                    tlName: "Andi Perkoso",
                    region: "East",
                    province: "DKI Jakarta",
                    area: "Jakarta Timur",
                    onContactAdmin: () {
                      // aksi jika tombol ditekan
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 8),
                            Text('April 2024', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RankWorkCardWidget(
                          rank: 3,
                          totalPeople: 30,
                          hoursWorked: 500,
                          totalHours: 1500,
                        ),
                        const SizedBox(height: 24),
                        SummaryCardWidget(
                          label1: "Target Call",
                          value1: "100",
                          label2: "Call",
                          value2: "50",
                          label3: "Achieve",
                          value3: "50%",
                        ),

                        SummaryCardWidget(
                          label1: "Target EC",
                          value1: "100",
                          label2: "EC",
                          value2: "50",
                          label3: "Achieve",
                          value3: "50%",
                        ),

                        SummaryCardWidget(
                          label1: "Target Val",
                          value1: "Rp1.000K",
                          label2: "Omzet",
                          value2: "Rp50K",
                          label3: "Achieve",
                          value3: "5%",
                        ),
                        const SizedBox(height: 24),
                        SalesLineChart(
                          dataPoints: [
                            FlSpot(0, 750000),
                            FlSpot(1, 500000),
                            FlSpot(2, 500000),
                            FlSpot(3, 200000),
                            FlSpot(4, 350000),
                            FlSpot(5, 500000),
                            FlSpot(6, 750000),
                          ],
                          labels: ['01 Feb', '02 Feb', '03 Feb', '04 Feb', '05 Feb', '06 Feb', '07 Feb'],
                          target: 1000000,
                        ),
                        const SizedBox(height: 24),
                        VisitingBarChart(
                          labels: ['01 Feb', '02 Feb', '03 Feb', '04 Feb', '05 Feb', '06 Feb'],
                          data: [
                            [500, 300, 250],
                            [750, 200, 240],
                            [500, 250, 200],
                            [250, 500, 200],
                            [750, 500, 250],
                            [500, 250, 200],
                          ],
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          children: [
                            _buildMenuIcon(Icons.inventory, 'Product List', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new ProductListScreen()));
                            }),
                            _buildMenuIcon(Icons.attach_money, 'Sales', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new SalesScreen()));
                            }),
                            _buildMenuIcon(Icons.access_time, 'Pending', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new PendingScreen()));
                            }),
                            _buildMenuIcon(Icons.groups, 'Presentation', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new PresentationScreen()));
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('To Do List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            ListTile(
                              title: Text('Toko Sinar Abadi'),
                              subtitle: Text('CI: 08:00 | CO: 08:30 | Durasi: 00:30'),
                              trailing: Icon(Icons.check_circle, color: Colors.green),
                            ),
                            ListTile(
                              title: Text('Toko Berkah'),
                              subtitle: Text('Belum dikunjungi'),
                              trailing: Icon(Icons.cancel, color: Colors.red),
                            ),
                            ListTile(
                              title: Text('Trijaya Store'),
                              subtitle: Text('Belum dikunjungi'),
                              trailing: Icon(Icons.cancel, color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Anda sedang mengunjungi outlet:\nTK Rindu Jaya, DKI Jakarta - Jaktim - GT',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '00:16:30',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for Check-in button
          Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new CheckinMapScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.location_on, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTabSelected: (i) => BottomMenu.onItemTapped(context, i),
        onCheckInPressed: () {
        },
      ),
    )
    );
  }

  Widget _buildMenuIcon(IconData iconData, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.lightBlue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
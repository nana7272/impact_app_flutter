import 'package:flutter/material.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';
import 'package:impact_app/widget/status_card_widget.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> visits = List.generate(
      4,
      (index) => {
        'store': 'TK SRI BUANA',
        'date': '2024-02-20',
        'checkIn': '19:19:57',
        'checkOut': '19:25:15',
        'duration': '00:06:42',
        'timestamp': '21 Feb, 19:19:57'
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Activity History'),
        bottom: TabBar(
          labelColor: Colors.blue,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.black,
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: Colors.blue,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'SPO'),
            Tab(text: 'Competitor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(visits),
          _buildSPOTab(),
          _buildCompetitorTab(),
        ],
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
    );
  }

  Widget _buildAttendanceTab(List<Map<String, String>> visits) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search here',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          Expanded(
            child: ListView.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(visit['store']!),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal: ${visit['date']}'),
                        Text('Jam Check in: ${visit['checkIn']}'),
                        Text('Jam Check out: ${visit['checkOut']}'),
                        Text('Durasi: ${visit['duration']}'),
                      ],
                    ),
                    trailing: Text(visit['timestamp']!),
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
    return Center(
      child: Text('SPO Data Akan Ditampilkan Disini'),
    );
  }

  Widget _buildCompetitorTab() {
    return Center(
      child: Text('Competitor Data Akan Ditampilkan Disini'),
    );
  }
}

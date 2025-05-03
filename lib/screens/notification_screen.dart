import 'package:flutter/material.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool hasNotifications = true; // Ubah ke false untuk coba mode kosong
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {
        'title': 'Anda belum checkout di toko: TK Rindu Jaya',
        'desc': 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        'date': '25 Februari 2024, 10:20',
        'image': 'https://cdn-icons-png.flaticon.com/512/7007/7007373.png'
      },
      {
        'title': 'Anda belum checkout di toko: TK Rindu Jaya',
        'desc': 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        'date': '25 Februari 2024, 10:20',
        'image': 'https://cdn-icons-png.flaticon.com/512/7007/7007373.png'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Notification'),
      ),
      body: hasNotifications ? ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(notif['date']!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      notif['image']!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(notif['desc']!),
                ],
              ),
            ),
          );
        },
      )
      : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/no_notification.png', height: 200),
            const SizedBox(height: 24),
            const Text('No Notification', style: TextStyle(fontSize: 20, color: Colors.blue)),
          ],
        ),
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
        currentIndex: 2,
        onTabSelected: (i) => BottomMenu.onItemTapped(context, i),
        onCheckInPressed: () {
        },
      ),
    );
  }
}
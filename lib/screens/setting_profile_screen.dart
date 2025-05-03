import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:impact_app/screens/checin_screen.dart';
import 'package:impact_app/screens/profile_screen.dart';
import 'package:impact_app/screens/sync_intro_screen.dart';
import 'package:impact_app/utils/bottom_menu_handler.dart';
import 'package:impact_app/widget/custom_navbar_bottom_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  int _selectedIndex = 3;
  bool hasNotifications = true; // Ubah ke false untuk coba mode kosong


  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text('Setting')
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            const SizedBox(height: 10),
            const Text('Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Motorist'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Akun'),
              subtitle: const Text('Kelola informasi profil untuk mengontrol, melindungi dan mengamankan akun'),
              onTap: () => _navigateTo(context, const MyProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Ganti Password'),
              subtitle: const Text('Kelola informasi profil untuk mengontrol, melindungi dan mengamankan akun'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sinkron Data'),
              subtitle: const Text('Kelola informasi profil untuk mengontrol, melindungi dan mengamankan akun'),
              onTap: () => _navigateTo(context, const SyncIntroScreen()),
            ),
            SizedBox(height: 12),
            Container(
              width: 300,
              child: ElevatedButton(
                
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.setString('userData', "");
                  SystemNavigator.pop();
                },
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ),
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
        currentIndex: _selectedIndex,
        onTabSelected: (i) => BottomMenu.onItemTapped(context, i),
        onCheckInPressed: () {
        },
      ),
    );
  }
}
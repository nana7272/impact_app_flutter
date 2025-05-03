import 'package:flutter/material.dart';
import 'package:impact_app/screens/sync_settings_screen.dart';

class SyncMainScreen extends StatelessWidget {
  const SyncMainScreen({super.key});

  Widget _buildSyncCard(String title, String percent, String count, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(percent, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(count, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset : false,
      appBar: AppBar(
        title: Text('Sync Data Local'),
        backgroundColor: Colors.grey[300],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search here',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.clear),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSyncCard('Data Outlet', '100.0% / 100%', '(50/50)', Icons.store, Colors.green),
                _buildSyncCard('Data Product', '0% / 0%', '(0/0)', Icons.inventory, Colors.blue),
                _buildSyncCard('Data Kecamatan', '0% / 0%', '(0/0)', Icons.location_city, Colors.blue),
                _buildSyncCard('Data Kelurahan', '0% / 0%', '(0/0)', Icons.apartment, Colors.blue),
              ],
            ),
            SizedBox(height: 24),
            Text("Cadangan Terakhir: 19 Februari 09.45", style: TextStyle(fontSize: 12)),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new SyncSettingsScreen()));
                },
                child: Text("Sync Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
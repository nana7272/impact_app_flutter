import 'package:flutter/material.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool pendingData = true;
  bool useMobileData = false;
  String frequency = 'Bulanan';

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempValue = frequency;
        return AlertDialog(
          title: Text('Frekuensi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Harian', 'Mingguan', 'Bulanan'].map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: tempValue,
                onChanged: (val) {
                  setState(() {
                    tempValue = val!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  frequency = tempValue;
                });
                Navigator.pop(context);
              },
              child: Text("Oke"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sync Data Local'),
        backgroundColor: Colors.grey[300],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Pengaturan Cadangan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Sinkronisasikan data Anda ke penyimpanan seluler anda. Anda dapat memulihkannya di telepon baru setelah mengunduh aplikasi',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text('Sinkronisasi terakhir: 19 Februari 09.45'),
            Text('Ukuran: 500 MB'),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Sync Data", style: TextStyle(color: Colors.white),),
            ),
            SizedBox(height: 24),
            ListTile(
              title: Text('Frekuensi'),
              subtitle: Text(frequency),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: _showFrequencyDialog,
            ),
            SwitchListTile(
              title: Text('Pending data sync'),
              subtitle: Text('450 MB'),
              value: pendingData,
              onChanged: (val) => setState(() => pendingData = val),
            ),
            SwitchListTile(
              title: Text('Cadangkan melalui data seluler'),
              value: useMobileData,
              onChanged: (val) => setState(() => useMobileData = val),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:impact_app/screens/sync_main_screen.dart';

class SyncIntroScreen extends StatelessWidget {
  const SyncIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Icon(Icons.access_time, size: 100, color: Colors.lightBlue),
            SizedBox(height: 24),
            Text(
              'Sinkronisasi Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Klik tombol panah kesamping jika ingin melakukan sinkronisasi data, atau klik skip jika langsung ke dashboard',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.lightBlue),
                SizedBox(width: 6),
                CircleAvatar(radius: 4, backgroundColor: Colors.grey[300]),
                SizedBox(width: 6),
                CircleAvatar(radius: 4, backgroundColor: Colors.grey[300]),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Skip', style: TextStyle(color: Colors.lightBlue)),
                ),
                FloatingActionButton(
                  heroTag: 'nextBtn',
                  backgroundColor: Colors.lightBlue,
                  onPressed: () {
                    Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new SyncMainScreen()));
                  },
                  child: Icon(Icons.arrow_forward),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
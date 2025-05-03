import 'package:flutter/material.dart';

class HeaderHomedWidget extends StatelessWidget {
  final String greeting;
  final String name;
  final String role;
  final String tlName;
  final String region;
  final String province;
  final String area;
  final VoidCallback onContactAdmin;

  const HeaderHomedWidget({
    super.key,
    required this.greeting,
    required this.name,
    required this.role,
    required this.tlName,
    required this.region,
    required this.province,
    required this.area,
    required this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: TextStyle(fontSize: 16)),
                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(role, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                Text('TL - $tlName', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),

          // Right side
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: StadiumBorder(),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.call, color: Colors.green[700]),
                  label: Text("Hubungi Admin"),
                  onPressed: onContactAdmin,
                ),
                SizedBox(height: 16),
                _infoRow("Region", region),
                _infoRow("Provinsi", province),
                _infoRow("Area", area),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(" : $value"),
        ],
      ),
    );
  }
}
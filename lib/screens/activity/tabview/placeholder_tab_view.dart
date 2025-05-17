// screens/activity/views/placeholder_tab_view.dart
import 'package:flutter/material.dart';

class PlaceholderTabView extends StatelessWidget {
  final String tabName;
  const PlaceholderTabView({Key? key, required this.tabName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
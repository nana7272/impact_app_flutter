import 'package:flutter/material.dart';

class RankWorkCardWidget extends StatelessWidget {
  final int rank;
  final int totalPeople;
  final int hoursWorked;
  final int totalHours;

  const RankWorkCardWidget({
    super.key,
    required this.rank,
    required this.totalPeople,
    required this.hoursWorked,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = totalHours == 0 ? 0 : (hoursWorked / totalHours) * 100;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Text("Your Rank", style: TextStyle(fontSize: 18)),
                SizedBox(height: 4),
                Text("$rank", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("of $totalPeople person", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Text("Work Hours", style: TextStyle(fontSize: 18)),
                SizedBox(height: 4),
                Text(
                  "$hoursWorked/$totalHours",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text("${percentage.toStringAsFixed(2)}%", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
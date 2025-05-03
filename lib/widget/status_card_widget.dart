import 'package:flutter/material.dart';

class StatusCardWidget extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color textColor;

  const StatusCardWidget({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 16)),
            ),
            SizedBox(height: 12),
            Text(count.toString(), style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
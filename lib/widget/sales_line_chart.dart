import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesLineChart extends StatefulWidget {
  final List<FlSpot> dataPoints;
  final List<String> labels;
  final double target;

  const SalesLineChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    required this.target,
  });

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  String selectedRange = '1 Month';
  final List<String> rangeOptions = ['1 Month', '3 Month', '6 Month', '12 Month'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Sales Stats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("01 Feb – 07 Feb", style: TextStyle(color: Colors.grey[600])),
            DropdownButton<String>(
              value: selectedRange,
              items: rangeOptions.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              underline: SizedBox(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRange = value;
                  });
                }
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: Text("Target ${widget.target.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < widget.labels.length) {
                        return Text(widget.labels[index], style: TextStyle(fontSize: 10));
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt().toString().replaceAllMapped(RegExp(r"(?=(\d{3})+(?!\d))"), (match) => ".")}",
                        style: TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: widget.dataPoints.length.toDouble() - 1,
              minY: 0,
              maxY: widget.target,
              lineBarsData: [
                LineChartBarData(
                  spots: widget.dataPoints,
                  isCurved: false,
                  barWidth: 3,
                  color: Colors.green,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
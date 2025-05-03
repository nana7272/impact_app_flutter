import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VisitingBarChart extends StatefulWidget {
  final List<String> labels;
  final List<List<double>> data;

  const VisitingBarChart({
    super.key,
    required this.labels,
    required this.data,
  });

  @override
  State<VisitingBarChart> createState() => _VisitingBarChartState();
}

class _VisitingBarChartState extends State<VisitingBarChart> {
  String selectedRange = '1 Month';
  final List<String> rangeOptions = ['1 Month', '3 Month', '6 Month', '12 Month'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Visiting", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
        SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(widget.data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: List.generate(widget.data[i].length, (j) {
                    return BarChartRodData(
                      toY: widget.data[i][j],
                      width: 10,
                      color: _barColor(j),
                      borderRadius: BorderRadius.circular(2),
                    );
                  }),
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < widget.labels.length) {
                        return Text(widget.labels[value.toInt()], style: TextStyle(fontSize: 10));
                      }
                      return Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
            ),
          ),
        ),
      ],
    );
  }

  Color _barColor(int index) {
    switch (index) {
      case 0:
        return Colors.cyan;
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
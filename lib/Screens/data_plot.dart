import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DataPlot extends StatefulWidget {
  DataPlot(this.data, {super.key});
  final List<double> data;

  @override
  State<DataPlot> createState() => _DataPlotState();
}

class _DataPlotState extends State<DataPlot> {

  List<FlSpot> dataPoints = [];

  @override
  void initState() {
    super.initState();
    // Convert data to FlSpot
    dataPoints = widget.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Received ECG data'))),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),

                  // Dynamically adjust the x-axis range to only show the last few points
                  minX: dataPoints.isEmpty ? 0 : dataPoints.first.x,
                  maxX: dataPoints.isEmpty ? 0 : dataPoints.last.x + 1,

                  // Set the y-axis range dynamically or fixed as per your data
                  maxY: widget.data.isEmpty ? 0 : widget.data.reduce((a, b) => a > b ? a : b) + .1,
                  minY: widget.data.isEmpty ? 0 : widget.data.reduce((a, b) => a < b ? a : b) - .1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

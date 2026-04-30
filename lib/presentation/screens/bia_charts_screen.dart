import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym_log/data/models/bia_report.dart';
import 'package:intl/intl.dart';

class BiaChartsScreen extends StatelessWidget {
  final List<BiaReport> reports;

  const BiaChartsScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    // Sort reports by date for meaningful charts
    final sortedReports = List<BiaReport>.from(reports)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('BIA Progress Charts'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildChartCard(
                context,
                'Weight (kg)',
                _generateDataPoints(sortedReports, (r) => r.weight),
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                context,
                'Body Fat (%)',
                _generateDataPoints(sortedReports, (r) => r.obesity.pbf),
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                context,
                'Fitness Score',
                _generateDataPoints(sortedReports, (r) => r.fitnessScore.toDouble()),
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                context,
                'Muscle Mass (kg)',
                _generateDataPoints(sortedReports, (r) => r.composition.muscle),
                Colors.red,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateDataPoints(List<BiaReport> sortedReports, double Function(BiaReport) getValue) {
    if (sortedReports.isEmpty) return [];
    
    final firstDate = sortedReports.first.recordDate;
    
    return sortedReports.map((report) {
      // Use days from first report as X coordinate
      final x = report.recordDate.difference(firstDate).inDays.toDouble();
      return FlSpot(x, getValue(report));
    }).toList();
  }

  Widget _buildChartCard(BuildContext context, String title, List<FlSpot> spots, Color color) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calculateBottomInterval(spots),
                        getTitlesWidget: (value, meta) {
                          if (reports.isEmpty) return const SizedBox.shrink();
                          final firstDate = sortedReports(reports).first.recordDate;
                          final date = firstDate.add(Duration(days: value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y}',
                            TextStyle(color: color, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateBottomInterval(List<FlSpot> spots) {
    if (spots.length < 2) return 1;
    final range = spots.last.x - spots.first.x;
    if (range == 0) return 1;
    return (range / 4).clamp(1, 400); // Show ~5 labels
  }

  List<BiaReport> sortedReports(List<BiaReport> list) {
    return List<BiaReport>.from(list)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gym_log/presentation/screens/dashboard_screen.dart'; // For ChartDataPoint and ChartRange

class WeightChartCard extends StatelessWidget {
  final List<ChartDataPoint> points;
  final ChartRange selectedRange;
  final ValueChanged<ChartRange> onRangeChanged;

  const WeightChartCard({
    super.key,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildRangeSelector(context),
          const SizedBox(height: 8),
          Expanded(
            child: points.isEmpty
                ? const Center(child: Text('No trends available yet'))
                : LineChart(_getChartData(colorScheme)),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<ChartRange>(
        segments: ChartRange.values.map((range) {
          return ButtonSegment<ChartRange>(
            value: range,
            label: Text(range.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          );
        }).toList(),
        selected: {selectedRange},
        onSelectionChanged: (Set<ChartRange> newSelection) {
          onRangeChanged(newSelection.first);
        },
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
          selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  LineChartData _getChartData(ColorScheme colorScheme) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: _calculateBottomInterval(points),
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(1)} ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: points.map((p) {
            return FlSpot(
              p.date.millisecondsSinceEpoch.toDouble(),
              p.weight,
            );
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.35,
          color: colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: points.length < 15,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 5,
              color: colorScheme.primary,
              strokeWidth: 3,
              strokeColor: colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.primary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => colorScheme.surfaceContainerHighest,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${spot.y} kg',
                TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '\n${DateFormat('MMM d').format(date)}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  double _calculateBottomInterval(List<ChartDataPoint> points) {
    if (points.length < 2) return 1;
    final first = points.first.date.millisecondsSinceEpoch;
    final last = points.last.date.millisecondsSinceEpoch;
    final range = last - first;
    if (range == 0) return 1;
    return range / 3;
  }
}

import 'package:flutter/material.dart';
import 'package:gym_log/presentation/screens/dashboard_screen.dart'; // For ChartDataPoint

class WeightSummarySection extends StatelessWidget {
  final double currentWeight;
  final List<ChartDataPoint> points;

  const WeightSummarySection({
    super.key,
    required this.currentWeight,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final pastPoints = points.where((p) => p.date.isBefore(lastWeek)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double? diff;
    if (pastPoints.isNotEmpty) {
      diff = currentWeight - pastPoints.first.weight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CURRENT WEIGHT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${currentWeight.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (diff != null) _buildDiffIndicator(context, diff),
        ],
      ),
    );
  }

  Widget _buildDiffIndicator(BuildContext context, double diff) {
    final isIncrease = diff > 0;
    final color = isIncrease ? Colors.redAccent : Colors.greenAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${isIncrease ? '+' : ''}${diff.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          'Last 7 days',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

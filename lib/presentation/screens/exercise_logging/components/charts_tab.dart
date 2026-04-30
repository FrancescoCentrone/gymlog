import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym_log/data/models/workout_set.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';

class ChartsTab extends ConsumerStatefulWidget {
  final int exerciseId;

  const ChartsTab({super.key, required this.exerciseId});

  @override
  ConsumerState<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends ConsumerState<ChartsTab> {
  int _selectedChartIndex = 0; // 0: Volume, 1: Max Weight

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<DateTime, List<WorkoutSet>>>(
      future: ref.read(workoutRepositoryProvider).getExerciseHistory(widget.exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final history = snapshot.data ?? {};
        
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No data yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Start logging to see your progress chart!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Calculate chart data based on selection
        final chartData = <DateTime, double>{};
        String chartTitle = '';
        String chartSubtitle = '';

        if (_selectedChartIndex == 0) {
          // Volume
          chartTitle = 'Volume & Workload';
          chartSubtitle = 'Total volume (kg) per workout';
          history.forEach((date, sets) {
            final totalVolume = sets.fold<double>(0, (sum, set) => sum + (set.weight * set.reps));
            if (totalVolume > 0) {
              chartData[date] = totalVolume;
            }
          });
        } else {
          // Max Weight
          chartTitle = 'Max Weight';
          chartSubtitle = 'Heaviest weight (kg) lifted per workout';
          history.forEach((date, sets) {
            final maxWeight = sets.fold<double>(0, (max, set) => set.weight > max ? set.weight : max);
            if (maxWeight > 0) {
              chartData[date] = maxWeight;
            }
          });
        }
        
        if (chartData.isEmpty) {
           return const Center(child: Text('Not enough data for this chart'));
        }

        // Sort by date ascending for chart
        final sortedDates = chartData.keys.toList()..sort();
        
        // Create data points
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedDates.length; i++) {
          final date = sortedDates[i];
          spots.add(FlSpot(i.toDouble(), chartData[date]!));
        }

        // Find min/max for Y-axis
        final values = chartData.values.toList();
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        final minValue = values.reduce((a, b) => a < b ? a : b);
        
        // Add some padding to Y-axis
        final minY = minValue * 0.9;
        final maxY = maxValue * 1.1;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart Selector
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 0, label: Text('Volume'), icon: Icon(Icons.bar_chart)),
                    ButtonSegment<int>(value: 1, label: Text('Max Weight'), icon: Icon(Icons.fitness_center)),
                  ],
                  selected: {_selectedChartIndex},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedChartIndex = newSelection.first;
                    });
                  },
                ),
              ),
              
              Text(
                chartTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                chartSubtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedDates.length) {
                             if (sortedDates.length > 5 && index % (sortedDates.length ~/ 5) != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${sortedDates[index].day}/${sortedDates[index].month}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(), 
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (sortedDates.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

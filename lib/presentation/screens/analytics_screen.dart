import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Volume',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Select a muscle group to see weekly sets volume.'),
            const SizedBox(height: 16),
            
            // Muscle Group Selector
            DropdownButtonFormField<MuscleGroup>(
              value: _selectedMuscleGroup,
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: MuscleGroup.values.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMuscleGroup = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Chart
            SizedBox(
              height: 300,
              child: FutureBuilder<Map<DateTime, Map<MuscleGroup, double>>>(
                future: ref.read(workoutRepositoryProvider).getWeeklySetsByMuscleGroup(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final weeklyData = snapshot.data ?? {};
                  if (weeklyData.isEmpty) {
                    return const Center(child: Text('No workout data available.'));
                  }

                  // Process data for the selected muscle group
                  // Map<DateTime, double> -> Week Start Date -> Set Count
                  final chartData = <DateTime, double>{};
                  
                  // Sort weeks
                  final sortedWeeks = weeklyData.keys.toList()..sort();
                  
                  // Filter last 12 weeks for better visualization if there are too many
                  final weeksToShow = sortedWeeks.length > 12 
                      ? sortedWeeks.sublist(sortedWeeks.length - 12) 
                      : sortedWeeks;

                  double maxSets = 0;
                  for (final week in weeksToShow) {
                    final count = weeklyData[week]?[_selectedMuscleGroup] ?? 0.0;
                    chartData[week] = count;
                    if (count > maxSets) maxSets = count;
                  }

                  if (weeksToShow.isEmpty || maxSets == 0) {
                     return Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                           const SizedBox(height: 8),
                           Text('No sets found for ${_selectedMuscleGroup.displayName}', style: const TextStyle(color: Colors.grey)),
                         ],
                       ),
                     );
                  }

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxSets + 2).toDouble(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceContainerHighest,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final weekIndex = group.x.toInt();
                            if (weekIndex >= 0 && weekIndex < weeksToShow.length) {
                              final date = weeksToShow[weekIndex];
                              final dateStr = DateFormat('MMM d').format(date);
                              final value = rod.toY;
                              // Format: if whole number show integer, else show 1 decimal
                              final valueStr = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
                              
                              return BarTooltipItem(
                                '$dateStr\n',
                                const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '$valueStr sets',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < weeksToShow.length) {
                                final date = weeksToShow[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeksToShow.asMap().entries.map((entry) {
                        final index = entry.key;
                        final date = entry.value;
                        final count = chartData[date] ?? 0;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: (maxSets + 2).toDouble(),
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


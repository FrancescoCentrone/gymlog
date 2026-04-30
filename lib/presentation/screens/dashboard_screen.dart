import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/presentation/state/bia_report_provider.dart';
import 'package:gym_log/presentation/state/weight_provider.dart';
import 'package:intl/intl.dart';
import 'package:gym_log/data/models/bia_report.dart';
import 'package:gym_log/data/models/weight_log.dart';
import 'package:gym_log/presentation/widgets/dashboard/weight_chart_card.dart';
import 'package:gym_log/presentation/widgets/dashboard/weight_summary_section.dart';
import 'package:gym_log/presentation/widgets/dashboard/weight_entry_section.dart';

enum ChartRange {
  week,
  month,
  threeMonths,
  sixMonths,
  year;

  String get label {
    switch (this) {
      case ChartRange.week: return '1W';
      case ChartRange.month: return '1M';
      case ChartRange.threeMonths: return '3M';
      case ChartRange.sixMonths: return '6M';
      case ChartRange.year: return '1Y';
    }
  }

  Duration get duration {
    switch (this) {
      case ChartRange.week: return const Duration(days: 7);
      case ChartRange.month: return const Duration(days: 30);
      case ChartRange.threeMonths: return const Duration(days: 90);
      case ChartRange.sixMonths: return const Duration(days: 180);
      case ChartRange.year: return const Duration(days: 365);
    }
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ChartRange _selectedRange = ChartRange.week;
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final log = WeightLog(
        recordDate: DateTime.now(),
        weight: weight,
      );

      await ref.read(weightLogsProvider.notifier).addWeightLog(log);
      _weightController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Weight logged successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  // Combined data point for charts
  List<ChartDataPoint> _getMergedData(List<BiaReport> reports, List<WeightLog> logs) {
    final List<ChartDataPoint> points = [];
    for (final r in reports) {
      points.add(ChartDataPoint(date: r.recordDate, weight: r.weight));
    }
    for (final l in logs) {
      points.add(ChartDataPoint(date: l.recordDate, weight: l.weight));
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  List<ChartDataPoint> _filterPoints(List<ChartDataPoint> points) {
    final now = DateTime.now();
    final cutoff = now.subtract(_selectedRange.duration);
    return points.where((p) => p.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(biaReportsProvider);
    final logsAsync = ref.watch(weightLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
            ),
            surfaceTintColor: Colors.transparent,
            backgroundColor: theme.colorScheme.surface,
          ),
          reportsAsync.when(
            data: (reports) => logsAsync.when(
              data: (logs) {
                final allPoints = _getMergedData(reports, logs);
                final filteredPoints = _filterPoints(allPoints);
                final now = DateTime.now();
                
                final currentWeight = allPoints.isNotEmpty ? allPoints.last.weight : null;
                final isReportedToday = allPoints.any((p) => 
                  p.date.year == now.year && 
                  p.date.month == now.month && 
                  p.date.day == now.day);

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        WeightChartCard(
                          points: filteredPoints,
                          selectedRange: _selectedRange,
                          onRangeChanged: (range) {
                            setState(() {
                              _selectedRange = range;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (currentWeight != null) 
                          WeightSummarySection(
                            currentWeight: currentWeight,
                            points: allPoints,
                          ),
                        if (!isReportedToday) ...[
                          const SizedBox(height: 12),
                          WeightEntrySection(
                            formKey: _formKey,
                            controller: _weightController,
                            onSave: _saveWeight,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }
}

class ChartDataPoint {
  final DateTime date;
  final double weight;

  ChartDataPoint({required this.date, required this.weight});
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/presentation/state/bia_report_provider.dart';
import 'package:gym_log/presentation/screens/bia_report_form_screen.dart';
import 'package:intl/intl.dart';

class BiaReportDetailScreen extends ConsumerWidget {
  final int reportId;

  const BiaReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(biaReportByIdProvider(reportId));

    return reportAsync.when(
      data: (report) {
        if (report == null) {
          return const Scaffold(
            body: Center(child: Text('Report not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Body Composition Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Record',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BiaReportFormScreen(initialReport: report),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete Record',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Record'),
                        content: const Text(
                          'Are you sure you want to delete this body composition record?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true && report.id != null) {
                    await ref.read(biaReportsProvider.notifier).deleteBiaReport(report.id!);
                    if (context.mounted) {
                      Navigator.pop(context); // Go back to list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Record deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd MMMM yyyy').format(report.recordDate),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildHeaderMetric(
                                context,
                                Icons.monitor_weight,
                                'Weight',
                                '${report.weight.toStringAsFixed(1)} kg',
                              ),
                              _buildHeaderMetric(
                                context,
                                Icons.stars,
                                'Fitness Score',
                                '${report.fitnessScore}/100',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Body Composition Section
                  _buildSectionHeader('Body Composition'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSimpleMetricRow(context, 'Muscle Mass', report.composition.muscle, 'kg'),
                          const Divider(),
                          _buildSimpleMetricRow(context, 'Body Fat', report.composition.fat, 'kg'),
                          const Divider(),
                          _buildSimpleMetricRow(context, 'Total Body Water', report.composition.tbw, 'L'),
                          const Divider(),
                          _buildSimpleMetricRow(context, 'Fat-Free Mass', report.composition.ffm, 'kg'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Obesity Analysis Section
                  _buildSectionHeader('Obesity Analysis'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSimpleMetricRow(context, 'BMI', report.obesity.bmi, ''),
                          const Divider(),
                          _buildSimpleMetricRow(context, 'Body Fat Percentage', report.obesity.pbf, '%'),
                          const Divider(),
                          _buildSimpleMetricRow(
                            context,
                            'Visceral Fat Level',
                            report.obesity.visceralFatLevel.toDouble(),
                            '',
                            isInteger: true,
                          ),
                          const Divider(),
                          _buildSimpleMetricRow(context, 'Basal Metabolic Rate', report.obesity.bmr, 'kcal'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHeaderMetric(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Icon(icon, size: 32, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMetricRow(BuildContext context, String label, double value, String unit, {bool isInteger = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '${isInteger ? value.toInt() : value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

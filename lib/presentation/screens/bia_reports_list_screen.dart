import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/bia_report.dart';
import 'package:gym_log/presentation/state/bia_report_provider.dart';
import 'package:gym_log/presentation/screens/bia_report_detail_screen.dart';
import 'package:gym_log/presentation/screens/bia_report_form_screen.dart';
import 'package:gym_log/presentation/screens/bia_charts_screen.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class BiaReportsListScreen extends ConsumerWidget {
  const BiaReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(biaReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Composition'),
        actions: [
          reportsAsync.when(
            data: (reports) => reports.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.bar_chart),
                    tooltip: 'View Progress Charts',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BiaChartsScreen(reports: reports),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        child: const Icon(Icons.add),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No body composition records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first record',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, ref, report);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, WidgetRef ref, BiaReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BiaReportDetailScreen(reportId: report.id!),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(report.recordDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      Icons.monitor_weight,
                      'Weight',
                      '${report.weight.toStringAsFixed(1)} kg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      Icons.fitness_center,
                      'BMI',
                      report.obesity.bmi.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      Icons.water_drop,
                      'Body Fat',
                      '${report.obesity.pbf.toStringAsFixed(1)}%',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      Icons.stars,
                      'Fitness Score',
                      '${report.fitnessScore}/100',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Body Composition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.edit_note, color: Colors.white),
                  ),
                  title: const Text('Manual Entry'),
                  subtitle: const Text('Enter your BIA metrics manually'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BiaReportFormScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('Take Picture'),
                  subtitle: const Text('Scan report using camera (AI-powered)'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleScan(context, ref, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text('Upload Picture'),
                  subtitle: const Text('Pick a report from your gallery'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handleScan(context, ref, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleScan(BuildContext context, WidgetRef ref, ImageSource source) async {
    print('DEBUG: _handleScan started for source: $source');
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image == null) {
      print('DEBUG: No image selected.');
      return;
    }

    print('DEBUG: Image selected: ${image.path}');
    if (!context.mounted) {
      print('DEBUG: Context unmounted after image selection');
      return;
    }

    // Show scanning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Scanning report locally...'),
                Text(
                  'No data leaves your device',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final scanningService = ref.read(biaScanningServiceProvider);
      final report = await scanningService.scanReport(image.path);

      if (!context.mounted) {
        print('DEBUG: Context unmounted after scanReport');
        return;
      }
      
      Navigator.pop(context); // Close scanning dialog
      print('DEBUG: Scanning dialog popped. Report is null: ${report == null}');

      if (report != null) {
        // Small delay to ensure the dialog is fully gone before pushing a new screen
        await Future.delayed(const Duration(milliseconds: 100));
        if (!context.mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BiaReportFormScreen(initialReport: report),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not extract data. Please try again or enter manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error in _handleScan: $e');
      if (!context.mounted) return;
      // Try to pop if still showing dialog (in case of error before pop)
      try { Navigator.pop(context); } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

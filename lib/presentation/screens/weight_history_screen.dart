import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/weight_log.dart';
import 'package:gym_log/presentation/state/weight_provider.dart';
import 'package:intl/intl.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(weightLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weight History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No weight entries yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildTile(context, ref, log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref, WeightLog log) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return Card(
      child: ListTile(
        title: Text('${log.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(formatter.format(log.recordDate)),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(context, ref, log),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, log),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WeightLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this weight entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(weightLogsProvider.notifier).deleteWeightLog(log.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight entry deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, WeightLog log) async {
    final weightController = TextEditingController(text: log.weight.toStringAsFixed(1));
    DateTime selectedDate = log.recordDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(log.recordDate);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Weight Entry'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  ));
                            }
                          },
                          child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
                          child: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text.trim());
                if (weight == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid weight'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final updated = WeightLog(
                  id: log.id,
                  weight: weight,
                  recordDate: selectedDate,
                );

                await ref.read(weightLogsProvider.notifier).updateWeightLog(updated);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weight entry updated'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    weightController.dispose();
  }
}

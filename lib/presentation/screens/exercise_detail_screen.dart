import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/history_tab.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/records_tab.dart';
import 'package:gym_log/presentation/screens/exercise_editor_screen.dart';
import 'package:gym_log/presentation/state/exercise_provider.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (list) {
        final current = list.firstWhere(
          (e) => e.id == exercise.id,
          orElse: () => exercise,
        );

        if (current.id == null) {
          return const Scaffold(body: Center(child: Text('Exercise not found')));
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(current.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseEditorScreen(initialExercise: current),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, ref, current),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'History'),
                  Tab(text: 'Records'),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildHeader(context, current),
                Expanded(
                  child: TabBarView(
                    children: [
                      HistoryTab(exerciseId: current.id!),
                      RecordsTab(exerciseId: current.id!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Exercise exercise) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description.isNotEmpty ? exercise.description : 'No description',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, 'Group: ${exercise.primaryMuscleGroup.displayName}'),
                _chip(context, 'Primary: ${exercise.primaryMuscle.displayName}'),
                if (exercise.secondaryMuscle != null)
                  _chip(context, 'Secondary: ${exercise.secondaryMuscle!.displayName}'),
                if (exercise.isCustom) _chip(context, 'Custom'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"?\n\n'
          'This will permanently delete:\n'
          '• All logged sets for this exercise\n'
          '• All references in routines\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && exercise.id != null) {
      await ref.read(exercisesProvider.notifier).deleteExercise(exercise.id!);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${exercise.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

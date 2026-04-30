import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/data/models/workout_session.dart';
import 'package:gym_log/presentation/screens/exercise_catalog_screen.dart';
import 'package:gym_log/presentation/screens/exercise_logging/exercise_logging_screen.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';

class WorkoutExerciseList extends ConsumerWidget {
  final DateTime selectedDate;

  const WorkoutExerciseList({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutExercisesAsync = ref.watch(workoutExercisesProvider);
    final workoutSetsAsync = ref.watch(workoutSetsProvider);

    return workoutExercisesAsync.when(
      data: (workoutExercises) {
        if (workoutExercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No exercises yet. Start your workout!'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _addExercise(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100.0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: workoutExercises.length,
          itemBuilder: (context, index) {

            final workoutExercise = workoutExercises[index];
            final allSets = workoutSetsAsync.valueOrNull ?? [];
            final exerciseSets = allSets
                .where((s) => s.exerciseId == workoutExercise.exerciseId)
                .toList();

            final routineExerciseProxy = RoutineExercise(
              id: -1,
              routineId: -1,
              exerciseId: workoutExercise.exerciseId,
              sets: workoutExercise.targetSets,
              minReps: workoutExercise.targetMinReps,
              maxReps: workoutExercise.targetMaxReps,
              restSeconds: workoutExercise.restSeconds,
              orderIndex: workoutExercise.orderIndex,
              exercise: workoutExercise.exercise,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: InkWell(
                onTap: () {
                  final workoutId = ref.read(currentWorkoutIdProvider);
                  if (workoutId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseLoggingScreen(
                          routineExercise: routineExerciseProxy,
                          workoutId: workoutId,
                        ),
                      ),
                    ).then((_) => ref.refresh(workoutSetsProvider));
                  }
                },
                onLongPress: () =>
                    _confirmRemoveExercise(context, ref, workoutExercise),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Hero(
                              tag: 'routine_${workoutExercise.exerciseId}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  workoutExercise.exercise?.name ??
                                      'Unknown Exercise',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workoutExercise.targetSets} sets • ${workoutExercise.targetMinReps}-${workoutExercise.targetMaxReps} reps',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12),
                      ),
                      if (exerciseSets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: exerciseSets.map((set) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${set.weight.toInt()}kg x ${set.reps}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final workoutId = ref.read(currentWorkoutIdProvider);

    if (workoutId != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen()),
      );

      if (result != null && context.mounted) {
        final exercise = result;
        final repository = ref.read(workoutRepositoryProvider);
        await repository.addExerciseToWorkout(workoutId, exercise.id);
        ref.refresh(workoutExercisesProvider);
      }
    } else {
      final repository = ref.read(workoutRepositoryProvider);
      final newSession = WorkoutSession(
        routineId: null,
        startTime: selectedDate,
      );
      final id = await repository.createWorkoutSession(newSession);
      ref.read(currentWorkoutIdProvider.notifier).state = id;

      if (!context.mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen()),
      );

      if (result != null && context.mounted) {
        final exercise = result;
        await repository.addExerciseToWorkout(id, exercise.id);
        ref.refresh(workoutExercisesProvider);
      }
    }
  }

  Future<void> _confirmRemoveExercise(
      BuildContext context, WidgetRef ref, workoutExercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text(
          'Remove "${workoutExercise.exercise?.name ?? 'this exercise'}" from today\'s workout?\n\nAll logged sets will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && workoutExercise.id != null) {
      try {
        await ref
            .read(workoutRepositoryProvider)
            .deleteWorkoutExercise(
                workoutExercise.workoutId, workoutExercise.exerciseId);
        ref.refresh(workoutExercisesProvider);
        ref.refresh(workoutSetsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise removed from workout')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing exercise: $e')),
          );
        }
      }
    }
  }
}

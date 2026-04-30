import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/repositories/workout_repository.dart';
import 'package:gym_log/data/models/workout_set.dart';
import 'package:gym_log/data/models/workout_exercise.dart';
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

final currentWorkoutIdProvider = StateProvider<int?>((ref) => null);

final workoutSetsProvider = FutureProvider.autoDispose<List<WorkoutSet>>((ref) async {
  final workoutId = ref.watch(currentWorkoutIdProvider);
  if (workoutId == null) return [];
  
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkoutSets(workoutId);
});

final workoutExercisesProvider = FutureProvider.autoDispose<List<WorkoutExercise>>((ref) async {
  final workoutId = ref.watch(currentWorkoutIdProvider);
  if (workoutId == null) return [];

  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkoutExercises(workoutId);
});

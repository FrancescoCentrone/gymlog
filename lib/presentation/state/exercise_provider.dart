import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/data/repositories/exercise_repository.dart';

// Repository Provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

// Exercises Notifier
class ExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getAllExercises();
  }

  Future<void> addExercise(Exercise exercise) async {
    final repository = ref.read(exerciseRepositoryProvider);
    await repository.createExercise(exercise);
    ref.invalidateSelf();
  }

  Future<void> updateExercise(Exercise exercise) async {
    final repository = ref.read(exerciseRepositoryProvider);
    await repository.updateExercise(exercise);
    ref.invalidateSelf();
  }

  Future<void> deleteExercise(int exerciseId) async {
    final repository = ref.read(exerciseRepositoryProvider);
    await repository.deleteExercise(exerciseId);
    ref.invalidateSelf();
  }
}

final exercisesProvider = AsyncNotifierProvider<ExercisesNotifier, List<Exercise>>(() {
  return ExercisesNotifier();
});

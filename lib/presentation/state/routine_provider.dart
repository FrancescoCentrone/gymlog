import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/data/repositories/routine_repository.dart';

// Repository Provider
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository();
});

// Routines Notifier
class RoutinesNotifier extends AsyncNotifier<List<Routine>> {
  late RoutineRepository _repository;

  @override
  Future<List<Routine>> build() async {
    _repository = ref.watch(routineRepositoryProvider);
    return await _repository.getAllRoutines();
  }

  Future<void> addRoutine(Routine routine) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRoutine(routine);
      ref.invalidateSelf(); // Refresh list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRoutine(routine);
      ref.invalidateSelf(); // Refresh list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRoutine(int id) async {
    // Optimistic update could be done here, but simple invalidation is safer for now
    try {
      await _repository.deleteRoutine(id);
      ref.invalidateSelf();
    } catch (e) {
       // Ideally show error to user, but for now we just keep state consistent
       ref.invalidateSelf();
    }
  }
}

// Routines Provider
final routinesProvider = AsyncNotifierProvider<RoutinesNotifier, List<Routine>>(() {
  return RoutinesNotifier();
});

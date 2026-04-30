import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/weight_log.dart';
import 'package:gym_log/data/repositories/weight_repository.dart';

final weightRepositoryProvider = Provider((ref) => WeightRepository());

final weightLogsProvider = StateNotifierProvider<WeightNotifier, AsyncValue<List<WeightLog>>>((ref) {
  return WeightNotifier(ref.watch(weightRepositoryProvider));
});

class WeightNotifier extends StateNotifier<AsyncValue<List<WeightLog>>> {
  final WeightRepository _repository;

  WeightNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWeightLogs();
  }

  Future<void> loadWeightLogs() async {
    try {
      final logs = await _repository.getAllWeightLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWeightLog(WeightLog log) async {
    try {
      await _repository.createWeightLog(log);
      await loadWeightLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWeightLog(WeightLog log) async {
    try {
      await _repository.updateWeightLog(log);
      await loadWeightLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWeightLog(int id) async {
    try {
      await _repository.deleteWeightLog(id);
      await loadWeightLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

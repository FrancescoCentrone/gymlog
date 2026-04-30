import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/bia_report.dart';
import 'package:gym_log/data/repositories/bia_report_repository.dart';
import 'package:gym_log/data/services/bia_scanning_service.dart';

// Repository Provider
final biaReportRepositoryProvider = Provider<BiaReportRepository>((ref) {
  return BiaReportRepository();
});

// Scanning Service Provider
final biaScanningServiceProvider = Provider<BiaScanningService>((ref) {
  return BiaScanningService();
});

// BIA Reports Notifier
class BiaReportsNotifier extends AsyncNotifier<List<BiaReport>> {
  late final BiaReportRepository _repository;

  @override
  Future<List<BiaReport>> build() async {
    _repository = ref.watch(biaReportRepositoryProvider);
    return await _repository.getAllBiaReports();
  }

  Future<void> addBiaReport(BiaReport report) async {
    state = const AsyncLoading();
    try {
      await _repository.createBiaReport(report);
      state = AsyncData(await _repository.getAllBiaReports());
    } catch (e, st) {
      state = AsyncError(e, st);
      // Rethrow so UI layers can present an error instead of a false success toast.
      rethrow;
    }
  }

  Future<void> updateBiaReport(BiaReport report) async {
    state = const AsyncLoading();
    try {
      await _repository.updateBiaReport(report);
      state = AsyncData(await _repository.getAllBiaReports());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteBiaReport(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteBiaReport(id);
      state = AsyncData(await _repository.getAllBiaReports());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final biaReportsProvider = AsyncNotifierProvider<BiaReportsNotifier, List<BiaReport>>(() {
  return BiaReportsNotifier();
});

final biaReportByIdProvider = Provider.family<AsyncValue<BiaReport?>, int>((ref, id) {
  final reportsAsync = ref.watch(biaReportsProvider);
  return reportsAsync.whenData((reports) => reports.where((r) => r.id == id).firstOrNull);
});

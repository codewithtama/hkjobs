import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardSummary> {
  String _startDate = '2020-01-01';
  String _endDate = '2030-12-31';

  @override
  Future<DashboardSummary> build() async {
    return _load(forceRefresh: false);
  }

  Future<DashboardSummary> _load({required bool forceRefresh}) async {
    final repo = ref.watch(dashboardRepositoryProvider);
    final result = await repo.fetchSummary(
      startDate: _startDate,
      endDate: _endDate,
      forceRefresh: forceRefresh,
    );
    switch (result) {
      case Success<DashboardSummary>(:final data):
        return data;
      case Failure<DashboardSummary>(:final error):
        throw error;
    }
  }

  Future<void> applyDateRange({
    required String startDate,
    required String endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    state = const AsyncLoading<DashboardSummary>();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<void> resetRange() async {
    await applyDateRange(startDate: '2020-01-01', endDate: '2030-12-31');
  }

  Future<void> refresh() async {
    state = const AsyncLoading<DashboardSummary>();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }
}

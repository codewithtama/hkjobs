import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../recruitment/data/recruitment_repository.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';

@immutable
class InterviewViewState {
  const InterviewViewState({
    required this.activeTab,
    required this.searchQuery,
    required this.totalCount,
    this.schedules = const <InterviewScheduleItem>[],
    this.candidates = const <InterviewCandidateItem>[],
  });

  final InterviewSubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final List<InterviewScheduleItem> schedules;
  final List<InterviewCandidateItem> candidates;
}

final interviewControllerProvider =
    AsyncNotifierProvider<InterviewController, InterviewViewState>(
  InterviewController.new,
);

class InterviewController extends AsyncNotifier<InterviewViewState> {
  InterviewSubTab _activeTab = InterviewSubTab.schedules;
  String _searchQuery = '';

  @override
  Future<InterviewViewState> build() async {
    return _fetchCurrent();
  }

  Future<InterviewViewState> _fetchCurrent() async {
    final repo = ref.watch(interviewRepositoryProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;

    if (_activeTab == InterviewSubTab.schedules) {
      final res = await repo.fetchSchedules(
        session: session,
        searchQuery: _searchQuery,
      );
      switch (res) {
        case Success<PaginatedList<InterviewScheduleItem>>(:final data):
          return InterviewViewState(
            activeTab: _activeTab,
            searchQuery: _searchQuery,
            totalCount: data.totalCount,
            schedules: data.items,
          );
        case Failure<PaginatedList<InterviewScheduleItem>>(:final error):
          throw error;
      }
    }

    final res = await repo.fetchCandidatesByTab(
      tab: _activeTab,
      searchQuery: _searchQuery,
    );
    switch (res) {
      case Success<PaginatedList<InterviewCandidateItem>>(:final data):
        return InterviewViewState(
          activeTab: _activeTab,
          searchQuery: _searchQuery,
          totalCount: data.totalCount,
          candidates: data.items,
        );
      case Failure<PaginatedList<InterviewCandidateItem>>(:final error):
        throw error;
    }
  }

  Future<void> selectTab(InterviewSubTab tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

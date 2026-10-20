import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';

@immutable
class AcademyViewState {
  const AcademyViewState({
    required this.activeTab,
    required this.searchQuery,
    required this.totalCount,
    this.waitingPlacements = const <PlacementWaitingItem>[],
    this.placementSchedules = const <PlacementScheduleItem>[],
    this.academyAccounts = const <AcademyAccountItem>[],
    this.psikotesQuestions = const <PsikotesQuestionItem>[],
    this.trainingRecords = const <TrainingOfflineRecord>[],
    this.fieldManagers = const <FieldManagerItem>[],
  });

  final AcademySubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final List<PlacementWaitingItem> waitingPlacements;
  final List<PlacementScheduleItem> placementSchedules;
  final List<AcademyAccountItem> academyAccounts;
  final List<PsikotesQuestionItem> psikotesQuestions;
  final List<TrainingOfflineRecord> trainingRecords;
  final List<FieldManagerItem> fieldManagers;
}

final academyControllerProvider =
    AsyncNotifierProvider<AcademyController, AcademyViewState>(
  AcademyController.new,
);

class AcademyController extends AsyncNotifier<AcademyViewState> {
  AcademySubTab _activeTab = AcademySubTab.placementWaiting;
  String _searchQuery = '';

  @override
  Future<AcademyViewState> build() async {
    return _fetchCurrent();
  }

  Future<AcademyViewState> _fetchCurrent() async {
    final repo = ref.watch(academyRepositoryProvider);

    switch (_activeTab) {
      case AcademySubTab.placementWaiting:
        final res =
            await repo.fetchPlacementWaiting(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<PlacementWaitingItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              waitingPlacements: data.items,
            );
          case Failure<PaginatedList<PlacementWaitingItem>>(:final error):
            throw error;
        }

      case AcademySubTab.placementSchedules:
        final res =
            await repo.fetchPlacementSchedules(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<PlacementScheduleItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              placementSchedules: data.items,
            );
          case Failure<PaginatedList<PlacementScheduleItem>>(:final error):
            throw error;
        }

      case AcademySubTab.academyNus:
        final res =
            await repo.fetchAcademyAccounts(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<AcademyAccountItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              academyAccounts: data.items,
            );
          case Failure<PaginatedList<AcademyAccountItem>>(:final error):
            throw error;
        }

      case AcademySubTab.psikotes:
        final res =
            await repo.fetchPsikotesQuestions(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<PsikotesQuestionItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              psikotesQuestions: data.items,
            );
          case Failure<PaginatedList<PsikotesQuestionItem>>(:final error):
            throw error;
        }

      case AcademySubTab.trainingOffline:
        final res =
            await repo.fetchTrainingRecords(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<TrainingOfflineRecord>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              trainingRecords: data.items,
            );
          case Failure<PaginatedList<TrainingOfflineRecord>>(:final error):
            throw error;
        }

      case AcademySubTab.fieldManagers:
        final res = await repo.fetchFieldManagers(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<FieldManagerItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              fieldManagers: data.items,
            );
          case Failure<PaginatedList<FieldManagerItem>>(:final error):
            throw error;
        }
    }
  }

  Future<void> selectTab(AcademySubTab tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _searchQuery = '';
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

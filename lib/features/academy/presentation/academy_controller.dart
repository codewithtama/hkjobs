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
    this.page = 1,
    this.pageSize = 20,
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
  final int page;
  final int pageSize;
  final List<PlacementWaitingItem> waitingPlacements;
  final List<PlacementScheduleItem> placementSchedules;
  final List<AcademyAccountItem> academyAccounts;
  final List<PsikotesQuestionItem> psikotesQuestions;
  final List<TrainingOfflineRecord> trainingRecords;
  final List<FieldManagerItem> fieldManagers;

  int get totalPages => (totalCount <= 0 || pageSize <= 0)
      ? 1
      : ((totalCount + pageSize - 1) ~/ pageSize);
}

final academyControllerProvider =
    AsyncNotifierProvider<AcademyController, AcademyViewState>(
      AcademyController.new,
    );

class AcademyController extends AsyncNotifier<AcademyViewState> {
  AcademySubTab _activeTab = AcademySubTab.placementWaiting;
  String _searchQuery = '';
  int _page = 1;
  static const int _pageSize = 20;

  @override
  Future<AcademyViewState> build() async {
    return _fetchCurrent();
  }

  Future<AcademyViewState> _fetchCurrent() async {
    final repo = ref.watch(academyRepositoryProvider);

    switch (_activeTab) {
      case AcademySubTab.placementWaiting:
        final res = await repo.fetchPlacementWaiting(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<PlacementWaitingItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              waitingPlacements: data.items,
            );
          case Failure<PaginatedList<PlacementWaitingItem>>(:final error):
            throw error;
        }

      case AcademySubTab.placementSchedules:
        final res = await repo.fetchPlacementSchedules(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<PlacementScheduleItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              placementSchedules: data.items,
            );
          case Failure<PaginatedList<PlacementScheduleItem>>(:final error):
            throw error;
        }

      case AcademySubTab.academyNus:
        final res = await repo.fetchAcademyAccounts(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<AcademyAccountItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              academyAccounts: data.items,
            );
          case Failure<PaginatedList<AcademyAccountItem>>(:final error):
            throw error;
        }

      case AcademySubTab.psikotes:
        final res = await repo.fetchPsikotesQuestions(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<PsikotesQuestionItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              psikotesQuestions: data.items,
            );
          case Failure<PaginatedList<PsikotesQuestionItem>>(:final error):
            throw error;
        }

      case AcademySubTab.trainingOffline:
        final res = await repo.fetchTrainingRecords(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<TrainingOfflineRecord>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              trainingRecords: data.items,
            );
          case Failure<PaginatedList<TrainingOfflineRecord>>(:final error):
            throw error;
        }

      case AcademySubTab.fieldManagers:
        final res = await repo.fetchFieldManagers(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<FieldManagerItem>>(:final data):
            return AcademyViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
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
    _page = 1;
    _searchQuery = '';
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    _page = 1;
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> goToPage(int page) async {
    if (_page == page || page < 1) return;
    _page = page;
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AcademyViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

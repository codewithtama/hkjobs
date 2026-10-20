import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/recruitment_repository.dart';
import '../domain/recruitment_models.dart';

@immutable
class RecruitmentViewState {
  const RecruitmentViewState({
    required this.activeTab,
    required this.searchQuery,
    required this.totalCount,
    this.page = 1,
    this.pageSize = 20,
    this.vacancies = const <JobVacancyItem>[],
    this.applications = const <VacancyApplicationItem>[],
    this.masterApplicants = const <MasterApplicantItem>[],
  });

  final RecruitmentSubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final int page;
  final int pageSize;
  final List<JobVacancyItem> vacancies;
  final List<VacancyApplicationItem> applications;
  final List<MasterApplicantItem> masterApplicants;

  int get totalPages => (totalCount <= 0 || pageSize <= 0)
      ? 1
      : ((totalCount + pageSize - 1) ~/ pageSize);
}

final recruitmentControllerProvider =
    AsyncNotifierProvider<RecruitmentController, RecruitmentViewState>(
  RecruitmentController.new,
);

class RecruitmentController extends AsyncNotifier<RecruitmentViewState> {
  RecruitmentSubTab _activeTab = RecruitmentSubTab.vacancies;
  String _searchQuery = '';
  int _page = 1;
  static const int _pageSize = 20;

  @override
  Future<RecruitmentViewState> build() async {
    return _fetchCurrent();
  }

  Future<RecruitmentViewState> _fetchCurrent() async {
    final repo = ref.watch(recruitmentRepositoryProvider);

    switch (_activeTab) {
      case RecruitmentSubTab.vacancies:
        final res = await repo.fetchVacancies(
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<JobVacancyItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              vacancies: data.items,
            );
          case Failure<PaginatedList<JobVacancyItem>>(:final error):
            throw error;
        }

      case RecruitmentSubTab.onProcess:
      case RecruitmentSubTab.approved:
      case RecruitmentSubTab.rejected:
        final res = await repo.fetchApplicationsByTab(
          tab: _activeTab,
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<VacancyApplicationItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              applications: data.items,
            );
          case Failure<PaginatedList<VacancyApplicationItem>>(:final error):
            throw error;
        }

      case RecruitmentSubTab.newComers:
      case RecruitmentSubTab.existing:
        final res = await repo.fetchMasterApplicants(
          isExisting: _activeTab == RecruitmentSubTab.existing,
          searchQuery: _searchQuery,
          page: _page,
          limit: _pageSize,
        );
        switch (res) {
          case Success<PaginatedList<MasterApplicantItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              masterApplicants: data.items,
            );
          case Failure<PaginatedList<MasterApplicantItem>>(:final error):
            throw error;
        }
    }
  }

  Future<void> selectTab(RecruitmentSubTab tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _page = 1;
    _searchQuery = '';
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    _page = 1;
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> goToPage(int page) async {
    if (_page == page || page < 1) return;
    _page = page;
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

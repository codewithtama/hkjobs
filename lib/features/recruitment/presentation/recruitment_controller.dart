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
    this.vacancies = const <JobVacancyItem>[],
    this.applications = const <VacancyApplicationItem>[],
    this.masterApplicants = const <MasterApplicantItem>[],
  });

  final RecruitmentSubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final List<JobVacancyItem> vacancies;
  final List<VacancyApplicationItem> applications;
  final List<MasterApplicantItem> masterApplicants;
}

final recruitmentControllerProvider =
    AsyncNotifierProvider<RecruitmentController, RecruitmentViewState>(
  RecruitmentController.new,
);

class RecruitmentController extends AsyncNotifier<RecruitmentViewState> {
  RecruitmentSubTab _activeTab = RecruitmentSubTab.vacancies;
  String _searchQuery = '';

  @override
  Future<RecruitmentViewState> build() async {
    return _fetchCurrent();
  }

  Future<RecruitmentViewState> _fetchCurrent() async {
    final repo = ref.watch(recruitmentRepositoryProvider);

    switch (_activeTab) {
      case RecruitmentSubTab.vacancies:
        final res = await repo.fetchVacancies(searchQuery: _searchQuery);
        switch (res) {
          case Success<PaginatedList<JobVacancyItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
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
        );
        switch (res) {
          case Success<PaginatedList<VacancyApplicationItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
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
        );
        switch (res) {
          case Success<PaginatedList<MasterApplicantItem>>(:final data):
            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
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
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<RecruitmentViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

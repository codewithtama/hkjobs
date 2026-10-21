import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/hk_filter_sheet.dart';
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
    this.filterData = HkFilterData.empty,
    this.availableVacancyCodes = const <String>[],
  });

  final RecruitmentSubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final int page;
  final int pageSize;
  final List<JobVacancyItem> vacancies;
  final List<VacancyApplicationItem> applications;
  final List<MasterApplicantItem> masterApplicants;
  final HkFilterData filterData;
  final List<String> availableVacancyCodes;

  String? get selectedVacancyFilter => filterData.vacancyCode;

  List<String> get availableCities {
    return applications
        .map((a) => a.city)
        .where((c) => c.isNotEmpty && c != '-')
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get availableGenders {
    return applications
        .map((a) => a.gender)
        .where((g) => g.isNotEmpty && g != '-')
        .toSet()
        .toList()
      ..sort();
  }

  int get totalPages => (totalCount <= 0 || pageSize <= 0)
      ? 1
      : ((totalCount + pageSize - 1) ~/ pageSize);

  List<VacancyApplicationItem> get filteredApplications {
    return applications.where((a) {
      if (filterData.vacancyCode != null &&
          filterData.vacancyCode!.isNotEmpty) {
        if (a.vacancyCode != filterData.vacancyCode) return false;
      }
      if (filterData.city != null && filterData.city!.isNotEmpty) {
        if (!a.city.toLowerCase().contains(filterData.city!.toLowerCase())) {
          return false;
        }
      }
      if (filterData.gender != null && filterData.gender!.isNotEmpty) {
        if (!a.gender.toLowerCase().contains(
          filterData.gender!.toLowerCase(),
        )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<VacancyApplicationItem>> get applicationsByVacancy {
    final map = <String, List<VacancyApplicationItem>>{};
    for (final item in filteredApplications) {
      final code = item.vacancyCode.isNotEmpty
          ? item.vacancyCode
          : 'Lainnya / Tanpa Kode';
      map.putIfAbsent(code, () => <VacancyApplicationItem>[]).add(item);
    }
    return map;
  }

  RecruitmentViewState copyWith({
    RecruitmentSubTab? activeTab,
    String? searchQuery,
    int? totalCount,
    int? page,
    int? pageSize,
    List<JobVacancyItem>? vacancies,
    List<VacancyApplicationItem>? applications,
    List<MasterApplicantItem>? masterApplicants,
    HkFilterData? filterData,
    List<String>? availableVacancyCodes,
  }) {
    return RecruitmentViewState(
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      vacancies: vacancies ?? this.vacancies,
      applications: applications ?? this.applications,
      masterApplicants: masterApplicants ?? this.masterApplicants,
      filterData: filterData ?? this.filterData,
      availableVacancyCodes:
          availableVacancyCodes ?? this.availableVacancyCodes,
    );
  }
}

final recruitmentControllerProvider =
    AsyncNotifierProvider<RecruitmentController, RecruitmentViewState>(
      RecruitmentController.new,
    );

class RecruitmentController extends AsyncNotifier<RecruitmentViewState> {
  RecruitmentSubTab _activeTab = RecruitmentSubTab.vacancies;
  String _searchQuery = '';
  HkFilterData _filterData = HkFilterData.empty;
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
          branchId: _filterData.branchId,
          startDate: _filterData.startDateFormatted,
          endDate: _filterData.endDateFormatted,
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
              filterData: _filterData,
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
            final codes =
                data.items
                    .map((a) => a.vacancyCode)
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            return RecruitmentViewState(
              activeTab: _activeTab,
              searchQuery: _searchQuery,
              totalCount: data.totalCount,
              page: _page,
              pageSize: _pageSize,
              applications: data.items,
              filterData: _filterData,
              availableVacancyCodes: codes,
            );
          case Failure<PaginatedList<VacancyApplicationItem>>(:final error):
            throw error;
        }

      case RecruitmentSubTab.newComers:
      case RecruitmentSubTab.existing:
        final res = await repo.fetchMasterApplicants(
          isExisting: _activeTab == RecruitmentSubTab.existing,
          experienceFilter: _filterData.experienceFilter,
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
              filterData: _filterData,
            );
          case Failure<PaginatedList<MasterApplicantItem>>(:final error):
            throw error;
        }
    }
  }

  Future<void> updateFilter(HkFilterData filter) async {
    final needsRefetch =
        _filterData.branchId != filter.branchId ||
        _filterData.startDate != filter.startDate ||
        _filterData.endDate != filter.endDate ||
        _filterData.experienceFilter != filter.experienceFilter;

    _filterData = filter;

    if (needsRefetch) {
      _page = 1;
      state = const AsyncLoading<RecruitmentViewState>();
      state = await AsyncValue.guard(_fetchCurrent);
    } else {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(filterData: filter));
      }
    }
  }

  void selectVacancyFilter(String? code) {
    updateFilter(_filterData.copyWith(vacancyCode: () => code));
  }

  Future<void> selectTab(RecruitmentSubTab tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _page = 1;
    _searchQuery = '';
    _filterData = HkFilterData.empty;
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

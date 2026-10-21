import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/hk_filter_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';

@immutable
class InterviewViewState {
  const InterviewViewState({
    required this.activeTab,
    required this.searchQuery,
    required this.totalCount,
    this.page = 1,
    this.pageSize = 20,
    this.schedules = const <InterviewScheduleItem>[],
    this.candidates = const <InterviewCandidateItem>[],
    this.filterData = HkFilterData.empty,
    this.availableInterviewCodes = const <String>[],
  });

  final InterviewSubTab activeTab;
  final String searchQuery;
  final int totalCount;
  final int page;
  final int pageSize;
  final List<InterviewScheduleItem> schedules;
  final List<InterviewCandidateItem> candidates;
  final HkFilterData filterData;
  final List<String> availableInterviewCodes;

  String? get selectedInterviewFilter => filterData.interviewCode;

  List<String> get availableVacancyCodes {
    return candidates
        .map((c) => c.vacancyCode)
        .where((v) => v.isNotEmpty && v != '-')
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get availableCities {
    return candidates
        .map((c) => c.city)
        .where((c) => c.isNotEmpty && c != '-')
        .toSet()
        .toList()
      ..sort();
  }

  int get totalPages => (totalCount <= 0 || pageSize <= 0)
      ? 1
      : ((totalCount + pageSize - 1) ~/ pageSize);

  List<InterviewCandidateItem> get filteredCandidates {
    return candidates.where((c) {
      if (filterData.interviewCode != null &&
          filterData.interviewCode!.isNotEmpty) {
        if (c.interviewCode != filterData.interviewCode) return false;
      }
      if (filterData.vacancyCode != null &&
          filterData.vacancyCode!.isNotEmpty) {
        if (c.vacancyCode != filterData.vacancyCode) return false;
      }
      if (filterData.city != null && filterData.city!.isNotEmpty) {
        if (!c.city.toLowerCase().contains(filterData.city!.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<InterviewCandidateItem>> get candidatesByInterview {
    final map = <String, List<InterviewCandidateItem>>{};
    for (final item in filteredCandidates) {
      final code = item.interviewCode.isNotEmpty && item.interviewCode != '-'
          ? item.interviewCode
          : 'Lainnya / Tanpa Jadwal';
      map.putIfAbsent(code, () => <InterviewCandidateItem>[]).add(item);
    }
    return map;
  }

  InterviewViewState copyWith({
    InterviewSubTab? activeTab,
    String? searchQuery,
    int? totalCount,
    int? page,
    int? pageSize,
    List<InterviewScheduleItem>? schedules,
    List<InterviewCandidateItem>? candidates,
    HkFilterData? filterData,
    List<String>? availableInterviewCodes,
  }) {
    return InterviewViewState(
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      schedules: schedules ?? this.schedules,
      candidates: candidates ?? this.candidates,
      filterData: filterData ?? this.filterData,
      availableInterviewCodes:
          availableInterviewCodes ?? this.availableInterviewCodes,
    );
  }
}

final interviewControllerProvider =
    AsyncNotifierProvider<InterviewController, InterviewViewState>(
      InterviewController.new,
    );

class InterviewController extends AsyncNotifier<InterviewViewState> {
  InterviewSubTab _activeTab = InterviewSubTab.schedules;
  String _searchQuery = '';
  HkFilterData _filterData = HkFilterData.empty;
  int _page = 1;
  static const int _pageSize = 20;

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
        branchId: _filterData.branchId,
        startDate: _filterData.startDateFormatted,
        endDate: _filterData.endDateFormatted,
        searchQuery: _searchQuery,
        page: _page,
        limit: _pageSize,
      );
      switch (res) {
        case Success<PaginatedList<InterviewScheduleItem>>(:final data):
          return InterviewViewState(
            activeTab: _activeTab,
            searchQuery: _searchQuery,
            totalCount: data.totalCount,
            page: _page,
            pageSize: _pageSize,
            schedules: data.items,
            filterData: _filterData,
          );
        case Failure<PaginatedList<InterviewScheduleItem>>(:final error):
          throw error;
      }
    }

    final res = await repo.fetchCandidatesByTab(
      tab: _activeTab,
      searchQuery: _searchQuery,
      page: _page,
      limit: _pageSize,
    );
    switch (res) {
      case Success<PaginatedList<InterviewCandidateItem>>(:final data):
        final codes =
            data.items
                .map((c) => c.interviewCode)
                .where((c) => c.isNotEmpty && c != '-')
                .toSet()
                .toList()
              ..sort();

        return InterviewViewState(
          activeTab: _activeTab,
          searchQuery: _searchQuery,
          totalCount: data.totalCount,
          page: _page,
          pageSize: _pageSize,
          candidates: data.items,
          filterData: _filterData,
          availableInterviewCodes: codes,
        );
      case Failure<PaginatedList<InterviewCandidateItem>>(:final error):
        throw error;
    }
  }

  Future<void> updateFilter(HkFilterData filter) async {
    final needsRefetch =
        _filterData.branchId != filter.branchId ||
        _filterData.startDate != filter.startDate ||
        _filterData.endDate != filter.endDate;

    _filterData = filter;

    if (needsRefetch && _activeTab == InterviewSubTab.schedules) {
      _page = 1;
      state = const AsyncLoading<InterviewViewState>();
      state = await AsyncValue.guard(_fetchCurrent);
    } else {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(filterData: filter));
      }
    }
  }

  void selectInterviewFilter(String? code) {
    updateFilter(_filterData.copyWith(interviewCode: () => code));
  }

  Future<void> selectTab(InterviewSubTab tab) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _page = 1;
    _searchQuery = '';
    _filterData = HkFilterData.empty;
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> updateSearch(String query) async {
    _searchQuery = query.trim();
    _page = 1;
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> goToPage(int page) async {
    if (_page == page || page < 1) return;
    _page = page;
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<InterviewViewState>();
    state = await AsyncValue.guard(_fetchCurrent);
  }
}

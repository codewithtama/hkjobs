import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/utils/html_cell_parser.dart';
import '../../recruitment/data/recruitment_repository.dart';
import '../domain/academy_models.dart';

export '../../recruitment/data/recruitment_repository.dart' show PaginatedList;

final academyRepositoryProvider = Provider<AcademyRepository>((ref) {
  return AcademyRepository(apiClient: ref.watch(hkJobsApiClientProvider));
});

class AcademyRepository {
  const AcademyRepository({required HkJobsApiClient apiClient})
      : _apiClient = apiClient;

  final HkJobsApiClient _apiClient;

  Future<Result<PaginatedList<PlacementWaitingItem>>> fetchPlacementWaiting({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.placementWaitingTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<PlacementWaitingItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<PlacementWaitingItem>>(
          PaginatedList<PlacementWaitingItem>(
            totalCount: data.totalRecords,
            items:
                data.rows.map(PlacementWaitingItem.fromDataTableRow).toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<PlacementScheduleItem>>> fetchPlacementSchedules({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.placementScheduleTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<PlacementScheduleItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<PlacementScheduleItem>>(
          PaginatedList<PlacementScheduleItem>(
            totalCount: data.totalRecords,
            items:
                data.rows.map(PlacementScheduleItem.fromDataTableRow).toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<AcademyAccountItem>>> fetchAcademyAccounts({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.academyAccountsTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<AcademyAccountItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<AcademyAccountItem>>(
          PaginatedList<AcademyAccountItem>(
            totalCount: data.totalRecords,
            items: data.rows.map(AcademyAccountItem.fromDataTableRow).toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<PsikotesQuestionItem>>> fetchPsikotesQuestions({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.psikotesTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<PsikotesQuestionItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<PsikotesQuestionItem>>(
          PaginatedList<PsikotesQuestionItem>(
            totalCount: data.totalRecords,
            items:
                data.rows.map(PsikotesQuestionItem.fromDataTableRow).toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<TrainingOfflineRecord>>> fetchTrainingRecords({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final passedRes = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.trainingOfflinePassedTable,
      length: limit,
      searchQuery: searchQuery,
    );
    final failedRes = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.trainingOfflineFailedTable,
      length: limit,
      searchQuery: searchQuery,
    );

    final combined = <TrainingOfflineRecord>[];
    int total = 0;

    if (passedRes case Success<ParsedDataTableResult>(:final data)) {
      total += data.totalRecords;
      combined.addAll(data.rows.map(TrainingOfflineRecord.fromDataTableRow));
    }
    if (failedRes case Success<ParsedDataTableResult>(:final data)) {
      total += data.totalRecords;
      combined.addAll(data.rows.map(TrainingOfflineRecord.fromDataTableRow));
    }
    if (passedRes is Failure<ParsedDataTableResult> &&
        failedRes is Failure<ParsedDataTableResult>) {
      return Failure<PaginatedList<TrainingOfflineRecord>>(passedRes.error);
    }

    return Success<PaginatedList<TrainingOfflineRecord>>(
      PaginatedList<TrainingOfflineRecord>(
        totalCount: total,
        items: combined,
      ),
    );
  }

  Future<Result<PaginatedList<FieldManagerItem>>> fetchFieldManagers({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.fieldManagerTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<FieldManagerItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<FieldManagerItem>>(
          PaginatedList<FieldManagerItem>(
            totalCount: data.totalRecords,
            items: data.rows.map(FieldManagerItem.fromDataTableRow).toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<TrainingScheduleSummaryItem>>> fetchTrainingSchedules({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.trainingListTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<TrainingScheduleSummaryItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<TrainingScheduleSummaryItem>>(
          PaginatedList<TrainingScheduleSummaryItem>(
            totalCount: data.totalRecords,
            items: data.rows
                .map(TrainingScheduleSummaryItem.fromDataTableRow)
                .toList(),
          ),
        );
    }
  }

  Future<Result<PaginatedList<TrainingParticipantItem>>> fetchTrainingParticipants(
    String trainingId, {
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.trainingParticipantsTable(trainingId),
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<TrainingParticipantItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        return Success<PaginatedList<TrainingParticipantItem>>(
          PaginatedList<TrainingParticipantItem>(
            totalCount: data.totalRecords,
            items: data.rows
                .map(TrainingParticipantItem.fromDataTableRow)
                .toList(),
          ),
        );
    }
  }

  Future<Result<Map<String, Object?>>> fetchTrainingParticipantStatus(
    String trainingListId,
  ) {
    return _apiClient.getJsonMap(
      ApiEndpoints.trainingParticipantStatusJson(trainingListId),
    );
  }

  Future<Result<void>> submitTrainingPassed({
    required String trainingListId,
    required String userId,
    required String reason,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.trainingUpdatePassed,
      () => FormData.fromMap(<String, Object>{
        'id_training_list_lolos': trainingListId,
        'id_user_lolos': userId,
        'alasanlolos': reason.trim(),
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<void>> submitTrainingFailed({
    required String trainingListId,
    required String userId,
    required String reason,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.trainingUpdateFailed,
      () => FormData.fromMap(<String, Object>{
        'id_training_list_tidaklolos': trainingListId,
        'id_user_tidaklolos': userId,
        'alasanTidaklolos': reason.trim(),
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<PaginatedList<PlacementPersonnelItem>>> fetchPlacementPersonnel(
    String placementId, {
    String searchQuery = '',
    int limit = 50,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.placementPersonnelTable(placementId),
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<PlacementPersonnelItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items =
            data.rows.map(PlacementPersonnelItem.fromDataTableRow).toList();
        return Success<PaginatedList<PlacementPersonnelItem>>(
          PaginatedList<PlacementPersonnelItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<void>> bypassPlacementToOps({
    required String waitingListPlacementId,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.placementBypassToOps,
      () => FormData.fromMap(<String, Object>{
        'id_waiting_listPenempatan': waitingListPlacementId,
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<void>> assignCandidateToPlacement({
    required String waitingListPlacementId,
    required String placementScheduleId,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.placementAssignCandidate,
      () => FormData.fromMap(<String, Object>{
        'id_waiting_listPenempatan': waitingListPlacementId,
        'id_penempatanSchedule': placementScheduleId,
        'id_waiting_list_penempatan': waitingListPlacementId,
        'id_penempatan_schedule': placementScheduleId,
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<void>> resetOnlineTraining({
    required String userId,
    required String reason,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.trainingOnlineReset,
      () => FormData.fromMap(<String, Object>{
        'id_user': userId,
        'alasan': reason.trim(),
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<void>> bypassOnlineTraining({
    required String userId,
    required String reason,
  }) async {
    final res = await _apiClient.postFormJson(
      ApiEndpoints.trainingOnlineBypass,
      () => FormData.fromMap(<String, Object>{
        'id_user': userId,
        'alasan': reason.trim(),
      }),
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }
}

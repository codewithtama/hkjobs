import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/utils/html_cell_parser.dart';
import '../../auth/domain/admin_session.dart';
import '../../recruitment/data/recruitment_repository.dart';
import '../domain/interview_models.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository(apiClient: ref.watch(hkJobsApiClientProvider));
});

class InterviewRepository {
  const InterviewRepository({required HkJobsApiClient apiClient})
      : _apiClient = apiClient;

  final HkJobsApiClient _apiClient;

  Future<Result<PaginatedList<InterviewScheduleItem>>> fetchSchedules({
    required AdminSession? session,
    String searchQuery = '',
    int limit = 40,
  }) async {
    final endpoint = session?.role == AdminRole.interviewer
        ? ApiEndpoints.interviewerScheduleTable(session!.adminId)
        : ApiEndpoints.interviewListTable;

    final res = await _apiClient.fetchDataTable(
      endpoint: endpoint,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<InterviewScheduleItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items =
            data.rows.map(InterviewScheduleItem.fromDataTableRow).toList();
        return Success<PaginatedList<InterviewScheduleItem>>(
          PaginatedList<InterviewScheduleItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<PaginatedList<InterviewCandidateItem>>> fetchCandidatesByTab({
    required InterviewSubTab tab,
    String searchQuery = '',
    int limit = 40,
  }) async {
    final endpoint = switch (tab) {
      InterviewSubTab.confirmed => ApiEndpoints.interviewConfirmedTable,
      InterviewSubTab.passed => ApiEndpoints.interviewPassedTable,
      InterviewSubTab.failed => ApiEndpoints.interviewFailedTable,
      InterviewSubTab.canceled => ApiEndpoints.interviewCanceledTable,
      InterviewSubTab.schedules => ApiEndpoints.interviewConfirmedTable,
    };

    final res = await _apiClient.fetchDataTable(
      endpoint: endpoint,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<InterviewCandidateItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items =
            data.rows.map(InterviewCandidateItem.fromDataTableRow).toList();
        return Success<PaginatedList<InterviewCandidateItem>>(
          PaginatedList<InterviewCandidateItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<void>> submitEvaluation({
    required String userAdvertId,
    required InterviewEvaluationRubric rubric,
    String failureReason = '',
  }) async {
    if (!rubric.isPassed && failureReason.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          'Alasan ketidaklulusan wajib diisi karena skor di bawah 65.',
        ),
      );
    }

    final detailRes = await _apiClient.getJsonMap(
      ApiEndpoints.advertUserEditJson(userAdvertId),
    );
    switch (detailRes) {
      case Failure<Map<String, Object?>>(:final error):
        return Failure<void>(error);
      case Success<Map<String, Object?>>(:final data):
        final payload = <String, Object?>{
          'id_advert_user': userAdvertId,
          'id_advert': (data['id_advertisement'] ?? '').toString(),
          'id_position': (data['id_job_position_advert'] ?? '').toString(),
          'id_cabang': (data['id_branch_advert'] ?? '').toString(),
          'id_user_applicant': (data['id_user_applicant'] ?? '').toString(),
          'id_interview': (data['id_schedule_interview'] ?? '').toString(),
          'data_diri_verification':
              rubric.dataDiriSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'fisik_verification': rubric.fisikSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'pengalaman_verification':
              rubric.pengalamanAda ? 'Ada' : 'Tidak Ada',
          'pengalaman_sesuai':
              rubric.pengalamanSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'ijazah_verification':
              rubric.ijazahSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'skck_verification': rubric.skckSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'sio_verification': rubric.sioSesuai ? 'Sesuai' : 'Tidak Sesuai',
          'groomingRate': rubric.groomingRate.toString(),
          'intelejenRate': rubric.intelejenRate.toString(),
          'komunikasiRate': rubric.komunikasiRate.toString(),
          'kejujuranRate': rubric.kejujuranBase.toString(),
          'StatusHasil': rubric.totalScore.toString(),
          'status_pelamar': rubric.statusPelamarValue,
          'reasonNotApprove': failureReason.trim(),
        };

        final postRes = await _apiClient.postFormRaw(
          ApiEndpoints.interviewSubmitEvaluation,
          payload,
        );
        switch (postRes) {
          case Failure<String>(:final error):
            return Failure<void>(error);
          case Success<String>():
            return const Success<void>(null);
        }
    }
  }
}

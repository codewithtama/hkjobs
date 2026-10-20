import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/utils/html_cell_parser.dart';
import '../domain/recruitment_models.dart';

final recruitmentRepositoryProvider = Provider<RecruitmentRepository>((ref) {
  return RecruitmentRepository(apiClient: ref.watch(hkJobsApiClientProvider));
});

class PaginatedList<T> {
  const PaginatedList({
    required this.totalCount,
    required this.items,
  });

  final int totalCount;
  final List<T> items;
}

class RecruitmentRepository {
  const RecruitmentRepository({required HkJobsApiClient apiClient})
      : _apiClient = apiClient;

  final HkJobsApiClient _apiClient;

  Future<Result<PaginatedList<JobVacancyItem>>> fetchVacancies({
    String searchQuery = '',
    int limit = 40,
  }) async {
    final res = await _apiClient.fetchDataTable(
      endpoint: ApiEndpoints.advertisementListTable,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<JobVacancyItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items = data.rows.map(JobVacancyItem.fromDataTableRow).toList();
        return Success<PaginatedList<JobVacancyItem>>(
          PaginatedList<JobVacancyItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<PaginatedList<VacancyApplicationItem>>> fetchApplicationsByTab({
    required RecruitmentSubTab tab,
    String searchQuery = '',
    int limit = 40,
  }) async {
    final (String endpoint, String defaultStatus) = switch (tab) {
      RecruitmentSubTab.approved => (
          ApiEndpoints.advertisementApprovedTable,
          'Diterima',
        ),
      RecruitmentSubTab.rejected => (
          ApiEndpoints.advertisementNotApprovedTable,
          'Ditolak',
        ),
      _ => (
          ApiEndpoints.advertisementOnProcessTable,
          'On Process',
        ),
    };

    final res = await _apiClient.fetchDataTable(
      endpoint: endpoint,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<VacancyApplicationItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items = data.rows
            .map(
              (row) => VacancyApplicationItem.fromDataTableRow(
                row,
                defaultStatus: defaultStatus,
              ),
            )
            .toList();
        return Success<PaginatedList<VacancyApplicationItem>>(
          PaginatedList<VacancyApplicationItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<PaginatedList<MasterApplicantItem>>> fetchMasterApplicants({
    required bool isExisting,
    String searchQuery = '',
    int limit = 40,
  }) async {
    final endpoint = isExisting
        ? ApiEndpoints.applicantExistingTable
        : ApiEndpoints.applicantNewComerTable;
    final res = await _apiClient.fetchDataTable(
      endpoint: endpoint,
      length: limit,
      searchQuery: searchQuery,
    );
    switch (res) {
      case Failure<ParsedDataTableResult>(:final error):
        return Failure<PaginatedList<MasterApplicantItem>>(error);
      case Success<ParsedDataTableResult>(:final data):
        final items = data.rows
            .map(
              (row) => MasterApplicantItem.fromDataTableRow(
                row,
                isExisting: isExisting,
              ),
            )
            .toList();
        return Success<PaginatedList<MasterApplicantItem>>(
          PaginatedList<MasterApplicantItem>(
            totalCount: data.totalRecords,
            items: items,
          ),
        );
    }
  }

  Future<Result<ApplicantFullProfile>> fetchApplicantProfile(
    String applicantId,
  ) async {
    final res = await _apiClient.getJsonMap(
      ApiEndpoints.applicantInfoJson(applicantId),
    );
    switch (res) {
      case Failure<Map<String, Object?>>(:final error):
        return Failure<ApplicantFullProfile>(error);
      case Success<Map<String, Object?>>(:final data):
        return Success<ApplicantFullProfile>(
          ApplicantFullProfile.fromJson(data),
        );
    }
  }

  Future<Result<Map<String, Object?>>> fetchVacancyDetail(String id) {
    return _apiClient.getJsonMap(ApiEndpoints.advertisementDetailJson(id));
  }

  Future<Result<void>> submitApplicantReview({
    required String userAdvertId,
    required bool isApproved,
    String rejectionReason = '',
  }) async {
    if (!isApproved && rejectionReason.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure('Alasan penolakan wajib diisi jika ditolak.'),
      );
    }

    final detailRes = await _apiClient.getJsonMap(
      ApiEndpoints.advertUserEditJson(userAdvertId),
    );
    switch (detailRes) {
      case Failure<Map<String, Object?>>(:final error):
        return Failure<void>(error);
      case Success<Map<String, Object?>>(:final data):
        final advertId = (data['id_advertisement'] ?? '').toString();
        final applicantId = (data['id_user_applicant'] ?? '').toString();
        final postRes = await _apiClient.postFormRaw(
          ApiEndpoints.approveApplicantToSchedule,
          <String, Object?>{
            'id_advert_user': userAdvertId,
            'id_advert': advertId,
            'id_user_applicant': applicantId,
            'status_pelamar': isApproved ? 'Approved' : 'Not Approved',
            'reasonNotApprove': rejectionReason.trim(),
          },
        );
        switch (postRes) {
          case Failure<String>(:final error):
            return Failure<void>(error);
          case Success<String>(:final data):
            if (data.contains('error')) {
              return const Failure<void>(
                ServerFailure(
                  'Kuota jadwal interview untuk lowongan ini sudah penuh atau belum dibuat.',
                ),
              );
            }
            return const Success<void>(null);
        }
    }
  }
}

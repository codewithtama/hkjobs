import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../domain/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(apiClient: ref.watch(hkJobsApiClientProvider));
});

class _CachedDashboardEntry {
  const _CachedDashboardEntry({
    required this.summary,
    required this.expiresAt,
  });

  final DashboardSummary summary;
  final DateTime expiresAt;

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class DashboardRepository {
  DashboardRepository({required HkJobsApiClient apiClient})
      : _apiClient = apiClient;

  final HkJobsApiClient _apiClient;
  final Map<String, _CachedDashboardEntry> _cache =
      <String, _CachedDashboardEntry>{};

  static const Duration _cacheTtl = Duration(minutes: 5);

  Future<Result<DashboardSummary>> fetchSummary({
    String startDate = '2020-01-01',
    String endDate = '2030-12-31',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$startDate|$endDate';
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && cached.isValid) {
        return Success<DashboardSummary>(cached.summary);
      }
    }

    final rawResult = await _apiClient.postFormRaw(
      ApiEndpoints.dashboardFilter,
      <String, Object?>{
        'tgl1': startDate,
        'tgl2': endDate,
      },
    );

    switch (rawResult) {
      case Failure<String>(:final error):
        return Failure<DashboardSummary>(error);
      case Success<String>(:final data):
        try {
          final decoded = jsonDecode(data);
          if (decoded is! Map) {
            return const Failure<DashboardSummary>(ParseFailure());
          }
          final map = decoded.map(
            (key, value) => MapEntry(key.toString(), value as Object?),
          );
          final summary = DashboardSummary.fromJson(
            map,
            startDate: startDate,
            endDate: endDate,
          );
          _cache[cacheKey] = _CachedDashboardEntry(
            summary: summary,
            expiresAt: DateTime.now().add(_cacheTtl),
          );
          return Success<DashboardSummary>(summary);
        } on FormatException {
          return const Failure<DashboardSummary>(ParseFailure());
        }
    }
  }
}

import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/storage/secure_session_storage.dart';
import '../../../core/utils/html_cell_parser.dart';
import '../domain/admin_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(hkJobsApiClientProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});

class AuthRepository {
  const AuthRepository({
    required HkJobsApiClient apiClient,
    required SecureSessionStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final HkJobsApiClient _apiClient;
  final SecureSessionStorage _storage;

  Future<AdminSession?> restoreSession() async {
    final stored = await _storage.readSession();
    if (stored == null) return null;
    _apiClient.setMemoryCookie(stored.cookieHeader);
    return AdminSession(
      phone: stored.phone,
      displayName: stored.displayName,
      role: AdminRole.fromString(stored.roleName),
      adminId: stored.adminId,
    );
  }

  Future<Result<AdminSession>> login({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty || password.isEmpty) {
      return const Failure<AdminSession>(
        ValidationFailure('Nomor telepon dan kata sandi wajib diisi.'),
      );
    }

    try {
      final response = await _apiClient.postLoginRequest(
        phone: cleanPhone,
        password: password,
      );

      final cookie = HkJobsApiClient.extractSessionCookie(response.headers);
      if (cookie == null || cookie.isEmpty) {
        return const Failure<AdminSession>(
          ServerFailure('Server tidak mengembalikan sesi login yang valid.'),
        );
      }

      _apiClient.setMemoryCookie(cookie);

      String dashboardHtml = response.data ?? '';
      if (response.statusCode == 302 ||
          response.statusCode == 303 ||
          dashboardHtml.isEmpty) {
        final dashResult = await _apiClient.getRaw(ApiEndpoints.dashboard);
        switch (dashResult) {
          case Failure<String>(:final error):
            return Failure<AdminSession>(error);
          case Success<String>(:final data):
            dashboardHtml = data;
        }
      }

      final parsed = await Isolate.run(
        () => HtmlCellParser.parseDashboardIdentity(dashboardHtml),
      );

      if (parsed['isLoginPage'] == 'true') {
        _apiClient.clearMemoryCookie();
        return const Failure<AdminSession>(
          ValidationFailure(
            'Nomor telepon atau kata sandi tidak sesuai.',
          ),
        );
      }

      final displayName = parsed['displayName'] ?? 'ADMIN HK';
      final roleStr = parsed['role'] ?? 'Super Admin';
      final adminId = parsed['adminId'] ?? '52';

      await _storage.saveSession(
        StoredSessionData(
          cookieHeader: cookie,
          phone: cleanPhone,
          password: password,
          displayName: displayName,
          roleName: roleStr,
          adminId: adminId,
        ),
      );

      return Success<AdminSession>(
        AdminSession(
          phone: cleanPhone,
          displayName: displayName,
          role: AdminRole.fromString(roleStr),
          adminId: adminId,
        ),
      );
    } on DioException {
      return const Failure<AdminSession>(NetworkFailure());
    }
  }

  Future<void> logout() async {
    await _apiClient.getRaw(ApiEndpoints.logout);
    _apiClient.clearMemoryCookie();
    await _storage.clearSession();
  }
}

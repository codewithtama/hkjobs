import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/update_info.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository();
});

class AppUpdateRepository {
  AppUpdateRepository({
    Dio? dio,
    this.owner = 'codewithtama',
    this.repo = 'hkjobs',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: <String, String>{
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'HKJobs-Mobile-App',
                },
              ),
            );

  final Dio _dio;
  final String owner;
  final String repo;

  Future<Result<UpdateInfo>> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = packageInfo.buildNumber;

      final url = 'https://api.github.com/repos/$owner/$repo/releases/latest';
      final response = await _dio.get<Map<String, Object?>>(
        url,
        options: Options(
          validateStatus: (status) => status != null && (status == 200 || status == 404),
        ),
      );

      if (response.statusCode == 404 || response.data == null) {
        return Success<UpdateInfo>(
          UpdateInfo(
            currentVersion: currentBuild.isNotEmpty && currentBuild != '0'
                ? '$currentVersion+$currentBuild'
                : currentVersion,
            latestVersion: currentVersion,
            releaseTitle: 'Versi Terbaru',
            releaseNotes: 'Tidak ada pembaruan rilis di GitHub.',
            htmlUrl: 'https://github.com/$owner/$repo/releases',
            hasUpdate: false,
          ),
        );
      }

      final data = response.data!;
      final updateInfo = UpdateInfo.fromGitHubRelease(
        json: data,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      return Success<UpdateInfo>(updateInfo);
    } on DioException catch (dioErr) {
      return Failure<UpdateInfo>(
        NetworkFailure(
          dioErr.message ?? 'Gagal memeriksa pembaruan aplikasi ke GitHub.',
        ),
      );
    } catch (e) {
      return Failure<UpdateInfo>(
        ServerFailure('Terjadi kesalahan saat memeriksa pembaruan: $e'),
      );
    }
  }
}

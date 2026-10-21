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
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               headers: <String, String>{
                 'Accept': 'application/vnd.github.v3+json',
                 'User-Agent': 'HKJobs-Mobile-App',
               },
             ),
           );

  final Dio _dio;
  final String owner;
  final String repo;

  Future<UpdateInfo?> _checkFromManifest(
    String currentVersion,
    String currentBuild,
  ) async {
    try {
      final url =
          'https://raw.githubusercontent.com/$owner/$repo/main/version.json';
      final response = await _dio.get<Map<String, Object?>>(
        url,
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) => status == 200,
        ),
      );

      final data = response.data;
      if (data != null) {
        return UpdateInfo.fromManifestJson(
          json: data,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }
    } catch (_) {
      // Fallback silently to web redirect probe
    }
    return null;
  }

  Future<UpdateInfo?> _checkFromWebRedirect(
    String currentVersion,
    String currentBuild,
  ) async {
    try {
      final url = 'https://github.com/$owner/$repo/releases/latest';
      final response = await _dio.get<void>(
        url,
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      final location = response.headers.value('location');
      if (location != null && location.contains('/tag/')) {
        final tag = location.split('/tag/').last.split('?').first.trim();
        if (tag.isNotEmpty) {
          final cleanVersion = tag.replaceFirst(RegExp(r'^[vV]'), '');
          final hasUpdate = UpdateInfo.isVersionNewer(
            latestTag: tag,
            currentVersion: currentVersion,
            currentBuild: currentBuild,
          );
          return UpdateInfo(
            currentVersion: currentBuild.isNotEmpty && currentBuild != '0'
                ? '$currentVersion+$currentBuild'
                : currentVersion,
            latestVersion: cleanVersion,
            releaseTitle: 'Pembaruan Tersedia ($tag)',
            releaseNotes:
                'Versi terbaru $tag telah dirilis di GitHub. Unduh pembaruan untuk mendapatkan fitur dan perbaikan terbaru.',
            htmlUrl: location.startsWith('http')
                ? location
                : 'https://github.com$location',
            hasUpdate: hasUpdate,
            apkDownloadUrl:
                'https://github.com/$owner/$repo/releases/download/$tag/hkjobs-release.apk',
            publishedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // Fallback silently to REST API
    }
    return null;
  }

  Future<UpdateInfo?> _checkFromGitHubApi(
    String currentVersion,
    String currentBuild,
  ) async {
    try {
      final url = 'https://api.github.com/repos/$owner/$repo/releases/latest';
      final response = await _dio.get<Map<String, Object?>>(
        url,
        options: Options(validateStatus: (status) => status == 200),
      );

      final data = response.data;
      if (data != null) {
        return UpdateInfo.fromGitHubRelease(
          json: data,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }
    } catch (_) {
      // Ignored: could be 403 rate-limit
    }
    return null;
  }

  Future<Result<UpdateInfo>> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = packageInfo.buildNumber;

      // 1. Cek dari manifest CDN Fastly (raw.githubusercontent.com) - Bebas kuota rate limit 403
      final manifestInfo = await _checkFromManifest(
        currentVersion,
        currentBuild,
      );
      if (manifestInfo != null) {
        return Success<UpdateInfo>(manifestInfo);
      }

      // 2. Cek dari GitHub Web 302 redirect probe (github.com/releases/latest) - Bebas API rate limit
      final redirectInfo = await _checkFromWebRedirect(
        currentVersion,
        currentBuild,
      );
      if (redirectInfo != null) {
        return Success<UpdateInfo>(redirectInfo);
      }

      // 3. Cek dari GitHub REST API resmi (api.github.com)
      final apiInfo = await _checkFromGitHubApi(currentVersion, currentBuild);
      if (apiInfo != null) {
        return Success<UpdateInfo>(apiInfo);
      }

      return Success<UpdateInfo>(
        UpdateInfo(
          currentVersion: currentBuild.isNotEmpty && currentBuild != '0'
              ? '$currentVersion+$currentBuild'
              : currentVersion,
          latestVersion: currentVersion,
          releaseTitle: 'Versi Terbaru',
          releaseNotes: 'Aplikasi sudah menggunakan versi terbaru.',
          htmlUrl: 'https://github.com/$owner/$repo/releases',
          hasUpdate: false,
        ),
      );
    } catch (e) {
      return const Failure<UpdateInfo>(
        NetworkFailure(
          'Tidak dapat memeriksa pembaruan. Pastikan perangkat terhubung ke internet.',
        ),
      );
    }
  }
}

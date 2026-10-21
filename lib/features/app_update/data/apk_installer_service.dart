import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apkInstallerServiceProvider = Provider<ApkInstallerService>((ref) {
  return ApkInstallerService();
});

class ApkInstallerService {
  ApkInstallerService({MethodChannel? channel, Dio? dio})
    : _channel =
          channel ??
          const MethodChannel('id.hkindonesia.ops.hkjobs_mobile/app_installer'),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 10),
              followRedirects: true,
              maxRedirects: 5,
            ),
          );

  final MethodChannel _channel;
  final Dio _dio;

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String?> getDownloadDirectory() async {
    if (!isAndroid) return null;
    try {
      final dir = await _channel.invokeMethod<String>('getDownloadDir');
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<bool> canRequestPackageInstalls() async {
    if (!isAndroid) return true;
    try {
      final canInstall = await _channel.invokeMethod<bool>(
        'canRequestPackageInstalls',
      );
      return canInstall ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> openUnknownSourcesSettings() async {
    if (!isAndroid) return false;
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openUnknownSourcesSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> installApk(String filePath) async {
    if (!isAndroid) return false;
    try {
      final success = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[ApkInstallerService] installApk failed: $e');
      return false;
    }
  }

  Future<String> downloadApk({
    required String downloadUrl,
    required String fileName,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getDownloadDirectory();
    final targetDir = dir ?? Directory.systemTemp.path;
    final savePath = '$targetDir/$fileName';

    // Delete existing old download if present
    final file = File(savePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }

    await _dio.download(
      downloadUrl,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      deleteOnError: true,
    );

    return savePath;
  }
}

import 'package:flutter/foundation.dart';

@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.hasUpdate,
    this.apkDownloadUrl,
    this.publishedAt,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String htmlUrl;
  final bool hasUpdate;
  final String? apkDownloadUrl;
  final DateTime? publishedAt;

  static bool isVersionNewer({
    required String latestTag,
    required String currentVersion,
    String currentBuild = '0',
  }) {
    final cleanLatest = latestTag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanCurrent = currentVersion.trim().replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );

    final latestParts = cleanLatest.split('+');
    final latestSemVer = latestParts.first;
    final latestBuild = latestParts.length > 1
        ? int.tryParse(latestParts[1]) ?? 0
        : 0;

    final currentParts = cleanCurrent.split('+');
    final currentSemVer = currentParts.first;
    final parsedCurrentBuild = currentParts.length > 1
        ? int.tryParse(currentParts[1]) ?? (int.tryParse(currentBuild) ?? 0)
        : (int.tryParse(currentBuild) ?? 0);

    final latestSegments = latestSemVer
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentSegments = currentSemVer
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (latestSegments.length < 3) {
      latestSegments.add(0);
    }
    while (currentSegments.length < 3) {
      currentSegments.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (latestSegments[i] > currentSegments[i]) return true;
      if (latestSegments[i] < currentSegments[i]) return false;
    }

    return latestBuild > parsedCurrentBuild;
  }

  factory UpdateInfo.fromGitHubRelease({
    required Map<String, Object?> json,
    required String currentVersion,
    required String currentBuild,
  }) {
    final tagName = (json['tag_name'] ?? json['name'] ?? '').toString();
    final releaseTitle = (json['name'] ?? tagName).toString();
    final releaseNotes = (json['body'] ?? 'Tidak ada catatan rilis.')
        .toString();
    final htmlUrl = (json['html_url'] ?? '').toString();
    final publishedAtStr = json['published_at']?.toString();
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr)
        : null;

    String? apkDownloadUrl;
    final rawAssets = json['assets'];
    if (rawAssets is List) {
      for (final asset in rawAssets) {
        if (asset is Map<String, Object?>) {
          final name = (asset['name'] ?? '').toString().toLowerCase();
          if (name.endsWith('.apk')) {
            apkDownloadUrl = (asset['browser_download_url'] ?? '').toString();
            break;
          }
        }
      }
    }

    final hasUpdate = isVersionNewer(
      latestTag: tagName,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );

    return UpdateInfo(
      currentVersion: currentBuild.isNotEmpty && currentBuild != '0'
          ? '$currentVersion+$currentBuild'
          : currentVersion,
      latestVersion: tagName.replaceFirst(RegExp(r'^[vV]'), ''),
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      htmlUrl: htmlUrl,
      hasUpdate: hasUpdate,
      apkDownloadUrl: apkDownloadUrl,
      publishedAt: publishedAt,
    );
  }

  factory UpdateInfo.fromManifestJson({
    required Map<String, Object?> json,
    required String currentVersion,
    required String currentBuild,
  }) {
    final version = (json['version'] ?? '').toString();
    final buildNumber = (json['buildNumber'] ?? '0').toString();
    final tagName = version.isNotEmpty
        ? (version.startsWith('v') || version.startsWith('V')
              ? version
              : 'v$version')
        : '';
    final combinedLatestTag = buildNumber.isNotEmpty && buildNumber != '0'
        ? '$tagName+$buildNumber'
        : tagName;
    final releaseTitle = (json['title'] ?? 'Rilis $tagName').toString();
    final releaseNotes =
        (json['releaseNotes'] ?? 'Pembaruan aplikasi tersedia.').toString();
    final apkUrl = (json['apkUrl'] ?? '').toString();
    final htmlUrl = (json['htmlUrl'] ?? '').toString();
    final publishedAtStr = json['publishedAt']?.toString();
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr)
        : null;

    final hasUpdate = isVersionNewer(
      latestTag: combinedLatestTag,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );

    return UpdateInfo(
      currentVersion: currentBuild.isNotEmpty && currentBuild != '0'
          ? '$currentVersion+$currentBuild'
          : currentVersion,
      latestVersion: version.replaceFirst(RegExp(r'^[vV]'), ''),
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      htmlUrl: htmlUrl.isNotEmpty
          ? htmlUrl
          : 'https://github.com/codewithtama/hkjobs/releases',
      hasUpdate: hasUpdate,
      apkDownloadUrl: apkUrl.isNotEmpty ? apkUrl : null,
      publishedAt: publishedAt,
    );
  }
}

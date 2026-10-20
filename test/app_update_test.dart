import 'package:flutter_test/flutter_test.dart';
import 'package:hkjobs_mobile/features/app_update/domain/update_info.dart';

void main() {
  group('UpdateInfo version comparison', () {
    test('detects newer patch version', () {
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.0.1',
          currentVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('detects newer minor and major versions', () {
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.1.0',
          currentVersion: '1.0.9',
        ),
        isTrue,
      );
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v2.0.0',
          currentVersion: '1.9.9',
        ),
        isTrue,
      );
    });

    test('detects newer build number when semver matches', () {
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.0.0+2',
          currentVersion: '1.0.0',
          currentBuild: '1',
        ),
        isTrue,
      );
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: '1.0.0+5',
          currentVersion: '1.0.0+4',
        ),
        isTrue,
      );
    });

    test('returns false when version is equal or older', () {
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.0.0',
          currentVersion: '1.0.0',
        ),
        isFalse,
      );
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.0.0',
          currentVersion: '1.0.1',
        ),
        isFalse,
      );
      expect(
        UpdateInfo.isVersionNewer(
          latestTag: 'v1.0.0+1',
          currentVersion: '1.0.0',
          currentBuild: '2',
        ),
        isFalse,
      );
    });

    test('parses GitHub release payload and finds apk url', () {
      final fakeJson = <String, Object?>{
        'tag_name': 'v1.0.2',
        'name': 'Rilis Perbaikan Produksi 1.0.2',
        'body': 'Perbaikan fitur review dan penempatan.',
        'html_url': 'https://github.com/codewithtama/hkjobs/releases/tag/v1.0.2',
        'published_at': '2026-10-20T22:00:00Z',
        'assets': <Map<String, Object?>>[
          {
            'name': 'hkjobs-release.apk',
            'browser_download_url':
                'https://github.com/codewithtama/hkjobs/releases/download/v1.0.2/hkjobs-release.apk',
          },
          {
            'name': 'source.zip',
            'browser_download_url':
                'https://github.com/codewithtama/hkjobs/archive/v1.0.2.zip',
          },
        ],
      };

      final info = UpdateInfo.fromGitHubRelease(
        json: fakeJson,
        currentVersion: '1.0.0',
        currentBuild: '1',
      );

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, equals('1.0.2'));
      expect(info.currentVersion, equals('1.0.0+1'));
      expect(
        info.apkDownloadUrl,
        equals(
          'https://github.com/codewithtama/hkjobs/releases/download/v1.0.2/hkjobs-release.apk',
        ),
      );
      expect(info.releaseTitle, equals('Rilis Perbaikan Produksi 1.0.2'));
    });

    test('parses version.json manifest payload correctly', () {
      final manifestJson = <String, Object?>{
        'version': '1.0.1',
        'buildNumber': '4',
        'title': 'Rilis v1.0.1 (Build 4)',
        'releaseNotes': 'Pembaruan otomatis tanpa batas kuota.',
        'apkUrl':
            'https://github.com/codewithtama/hkjobs/releases/download/v1.0.1/hkjobs-release.apk',
        'htmlUrl': 'https://github.com/codewithtama/hkjobs/releases/tag/v1.0.1',
        'publishedAt': '2026-10-20T16:00:40Z',
      };

      final info = UpdateInfo.fromManifestJson(
        json: manifestJson,
        currentVersion: '1.0.0',
        currentBuild: '1',
      );

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, equals('1.0.1'));
      expect(info.currentVersion, equals('1.0.0+1'));
      expect(
        info.apkDownloadUrl,
        equals(
          'https://github.com/codewithtama/hkjobs/releases/download/v1.0.1/hkjobs-release.apk',
        ),
      );
      expect(info.releaseTitle, equals('Rilis v1.0.1 (Build 4)'));
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/apk_installer_service.dart';
import '../../domain/update_info.dart';
import '../app_update_controller.dart';

enum _DownloadStatus { idle, downloading, readyToInstall, error }

class AppUpdateDialog extends ConsumerStatefulWidget {
  const AppUpdateDialog({required this.info, super.key});

  final UpdateInfo info;

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  @override
  ConsumerState<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends ConsumerState<AppUpdateDialog> {
  _DownloadStatus _status = _DownloadStatus.idle;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedFilePath;
  String? _errorMessage;
  bool _canInstallUnknown = true;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _checkUnknownSourcePermission();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _checkUnknownSourcePermission() async {
    final service = ref.read(apkInstallerServiceProvider);
    if (!service.isAndroid) return;
    final allowed = await service.canRequestPackageInstalls();
    if (mounted) {
      setState(() {
        _canInstallUnknown = allowed;
      });
    }
  }

  Future<void> _startDownloadAndInstall() async {
    final apkUrl = widget.info.apkDownloadUrl;
    final service = ref.read(apkInstallerServiceProvider);

    if (apkUrl == null || !service.isAndroid) {
      // Fallback to browser
      await _openInBrowser();
      return;
    }

    setState(() {
      _status = _DownloadStatus.downloading;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
    });

    _cancelToken = CancelToken();

    try {
      final fileName = 'hkjobs_v${widget.info.latestVersion}.apk';
      final savePath = await service.downloadApk(
        downloadUrl: apkUrl,
        fileName: fileName,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
            _progress = total > 0 ? (received / total) : 0.0;
          });
        },
        cancelToken: _cancelToken,
      );

      if (!mounted) return;
      setState(() {
        _status = _DownloadStatus.readyToInstall;
        _downloadedFilePath = savePath;
      });

      // Automatically launch the APK installer!
      await _installApk(savePath);
    } catch (e) {
      if (!mounted) return;
      if (_cancelToken?.isCancelled ?? false) return;
      setState(() {
        _status = _DownloadStatus.error;
        _errorMessage = 'Gagal mengunduh berkas APK: $e';
      });
    }
  }

  Future<void> _installApk(String filePath) async {
    final service = ref.read(apkInstallerServiceProvider);
    final launched = await service.installApk(filePath);
    await _checkUnknownSourcePermission();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal membuka installer. Pastikan izin "Pasang aplikasi tidak dikenal" telah aktif.',
          ),
        ),
      );
    }
  }

  Future<void> _openUnknownSourcesSettings() async {
    final service = ref.read(apkInstallerServiceProvider);
    await service.openUnknownSourcesSettings();
    if (mounted) {
      await _checkUnknownSourcePermission();
    }
  }

  Future<void> _openInBrowser() async {
    final targetUrl = widget.info.apkDownloadUrl ?? widget.info.htmlUrl;
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka URL: $targetUrl')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const mb = 1024 * 1024;
    final mbValue = bytes / mb;
    return '${mbValue.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final isAndroid = ref.read(apkInstallerServiceProvider).isAndroid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.brandWarmMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: colors.brandWarm,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Tersedia!',
                          style: textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Versi terbaru telah dirilis di GitHub',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Versi Saat Ini',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${widget.info.currentVersion}',
                          style: textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.textMuted,
                      size: 18,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Versi Baru',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.successMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${widget.info.latestVersion}',
                            style: textStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Catatan Rilis (Changelog):',
                style: textStyles.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.info.releaseNotes.trim().isEmpty
                        ? 'Pembaruan stabilitas dan perbaikan bug.'
                        : widget.info.releaseNotes,
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_status == _DownloadStatus.downloading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.brandWarmMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.brandWarm.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mengunduh APK...',
                            style: textStyles.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toStringAsFixed(0)}%',
                            style: textStyles.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.brandWarm,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalBytes > 0 ? _progress : null,
                        backgroundColor: colors.border,
                        color: colors.brandWarm,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_status == _DownloadStatus.readyToInstall) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.successMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.success.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'APK berhasil diunduh!',
                              style: textStyles.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 Petunjuk Izin Sumber Tidak Dikenal:\n'
                        'Jika muncul peringatan sistem "Untuk alasan keamanan, ponsel Anda tidak diizinkan memasang aplikasi tidak dikenal dari sumber ini":\n'
                        '1. Klik Setelan pada dialog sistem.\n'
                        '2. Aktifkan Izinkan dari sumber ini.\n'
                        '3. Kembali dan tekan Pasang Ulang APK di bawah.',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.textPrimary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openUnknownSourcesSettings,
                              icon: const Icon(Icons.settings_rounded, size: 16),
                              label: const Text(
                                'Buka Setelan',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                if (_downloadedFilePath != null) {
                                  _installApk(_downloadedFilePath!);
                                }
                              },
                              icon: const Icon(Icons.install_mobile_rounded, size: 16),
                              label: const Text(
                                'Pasang Ulang',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (_status == _DownloadStatus.error) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.dangerMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.danger.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? 'Terjadi kesalahan saat mengunduh.',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.danger,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (widget.info.apkDownloadUrl != null && isAndroid) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: colors.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pemasangan otomatis in-app APK didukung (Sumber Tidak Dikenal).',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.success,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_canInstallUnknown) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Peringatan: Izin "Pasang aplikasi tidak dikenal" belum aktif.',
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.brandWarm,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  label: const Text(
                    'Unduh via Browser',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(appUpdateControllerProvider.notifier).dismissUpdate();
            Navigator.of(context).pop();
          },
          child: const Text('Nanti Saja'),
        ),
        if (_status == _DownloadStatus.idle || _status == _DownloadStatus.error)
          FilledButton.icon(
            onPressed: _startDownloadAndInstall,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              widget.info.apkDownloadUrl != null && isAndroid
                  ? 'Unduh & Pasang Sekarang'
                  : 'Buka Halaman Rilis',
            ),
          )
        else if (_status == _DownloadStatus.downloading)
          const FilledButton(
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Mengunduh...'),
              ],
            ),
          )
        else if (_status == _DownloadStatus.readyToInstall)
          FilledButton.icon(
            onPressed: () {
              if (_downloadedFilePath != null) {
                _installApk(_downloadedFilePath!);
              }
            },
            icon: const Icon(Icons.install_mobile_rounded, size: 18),
            label: const Text('Pasang APK'),
          ),
      ],
    );
  }
}

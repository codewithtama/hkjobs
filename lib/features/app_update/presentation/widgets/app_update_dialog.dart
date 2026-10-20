import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/update_info.dart';
import '../app_update_controller.dart';

class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({required this.info, super.key});

  final UpdateInfo info;

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    final targetUrl = info.apkDownloadUrl ?? info.htmlUrl;
    final uri = Uri.tryParse(targetUrl);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka URL: $targetUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        'v${info.currentVersion}',
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
                          'v${info.latestVersion}',
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
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes.trim().isEmpty
                      ? 'Pembaruan stabilitas dan perbaikan bug.'
                      : info.releaseNotes,
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (info.apkDownloadUrl != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'File APK siap diunduh secara langsung dari GitHub',
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.success,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
        FilledButton.icon(
          onPressed: () => _handleDownload(context),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(
            info.apkDownloadUrl != null
                ? 'Unduh & Pasang APK'
                : 'Buka Halaman Rilis',
          ),
        ),
      ],
    );
  }
}

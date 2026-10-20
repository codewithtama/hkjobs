import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class HkLoadingView extends StatelessWidget {
  const HkLoadingView({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HkErrorView extends StatelessWidget {
  const HkErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: colors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(AppStrings.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HkEmptyView extends StatelessWidget {
  const HkEmptyView({
    this.title = AppStrings.emptyListTitle,
    this.subtitle = AppStrings.emptyListSubtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum HkBadgeTone { neutral, accent, warm, success, warning, danger }

class HkStatusBadge extends StatelessWidget {
  const HkStatusBadge({
    required this.label,
    this.tone = HkBadgeTone.neutral,
    super.key,
  });

  final String label;
  final HkBadgeTone tone;

  factory HkStatusBadge.fromStatusText(String rawStatus) {
    final lower = rawStatus.toLowerCase();
    if (lower.contains('tidak') ||
        lower.contains('gagal') ||
        lower.contains('batal') ||
        lower.contains('not') ||
        lower.contains('failed') ||
        lower.contains('expired')) {
      return HkStatusBadge(label: rawStatus, tone: HkBadgeTone.danger);
    }
    if (lower.contains('aktif') ||
        lower.contains('active') ||
        lower.contains('lolos') ||
        lower.contains('passed') ||
        lower.contains('approved') ||
        lower.contains('diterima') ||
        lower.contains('konfirmasi') ||
        lower.contains('ongoing')) {
      return HkStatusBadge(label: rawStatus, tone: HkBadgeTone.success);
    }
    if (lower.contains('process') ||
        lower.contains('waiting') ||
        lower.contains('basic')) {
      return HkStatusBadge(label: rawStatus, tone: HkBadgeTone.warning);
    }
    return HkStatusBadge(label: rawStatus, tone: HkBadgeTone.accent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      HkBadgeTone.neutral => (colors.surfaceSubtle, colors.textMuted),
      HkBadgeTone.accent => (colors.accentMuted, colors.accent),
      HkBadgeTone.warm => (colors.brandWarmMuted, colors.brandWarm),
      HkBadgeTone.success => (colors.successMuted, colors.success),
      HkBadgeTone.warning => (colors.warningMuted, colors.warning),
      HkBadgeTone.danger => (colors.dangerMuted, colors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class HkSearchField extends StatelessWidget {
  const HkSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
    this.hintText = AppStrings.searchPlaceholder,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) {
              return IconButton(
                onPressed: () => onSubmitted(controller.text),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.accent,
                ),
              );
            }
            return IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: colors.textMuted),
            );
          },
        ),
      ),
    );
  }
}

class HkQrPreviewSheet extends StatelessWidget {
  const HkQrPreviewSheet({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    super.key,
  });

  final String title;
  final String subtitle;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: context.textStyles.titleLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: context.monoStyle.copyWith(color: colors.accent),
            ),
            const SizedBox(height: 20),
            Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, _, _) => Center(
                  child: Text(
                    imageUrl,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodySmall,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.closeButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

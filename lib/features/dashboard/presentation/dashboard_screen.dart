import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: DateTime(2025, 1, 1), end: now),
    );
    if (picked == null || !context.mounted) return;
    final fmt = DateFormat('yyyy-MM-dd');
    await ref
        .read(dashboardControllerProvider.notifier)
        .applyDateRange(
          startDate: fmt.format(picked.start),
          endDate: fmt.format(picked.end),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return state.when(
      loading: () => const HkLoadingView(message: AppStrings.loadingDashboard),
      error: (err, _) {
        final msg = err is AppFailure ? err.message : err.toString();
        return HkErrorView(
          message: msg,
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        );
      },
      data: (summary) {
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _DashboardFilterHeader(
                summary: summary,
                onPickRange: () => _pickDateRange(context, ref),
                onReset: () =>
                    ref.read(dashboardControllerProvider.notifier).resetRange(),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: AppStrings.sectionApplicantPool),
              const SizedBox(height: 10),
              _ApplicantHeroCard(summary: summary),
              const SizedBox(height: 20),
              const _SectionHeader(title: AppStrings.sectionVacancyFunnel),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: AppStrings.statusApproved,
                      value: summary.totalApprove.toString(),
                      tone: HkBadgeTone.success,
                      icon: Icons.verified_user_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: AppStrings.statusOnProcess,
                      value: summary.totalOnProcess.toString(),
                      tone: HkBadgeTone.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: AppStrings.statusRejected,
                      value: summary.totalNotApprove.toString(),
                      tone: HkBadgeTone.danger,
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: AppStrings.sectionInterviewFunnel),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.75,
                children: [
                  _MetricTile(
                    label: AppStrings.statusConfirmed,
                    value: summary.totalConfirmed.toString(),
                    tone: HkBadgeTone.accent,
                    icon: Icons.event_available_rounded,
                  ),
                  _MetricTile(
                    label: AppStrings.statusCanceled,
                    value: summary.totalCanceled.toString(),
                    tone: HkBadgeTone.neutral,
                    icon: Icons.event_busy_rounded,
                  ),
                  _MetricTile(
                    label: AppStrings.statusPassed,
                    value: summary.totalPassed.toString(),
                    tone: HkBadgeTone.success,
                    icon: Icons.workspace_premium_outlined,
                  ),
                  _MetricTile(
                    label: AppStrings.statusFailed,
                    value: summary.totalFailed.toString(),
                    tone: HkBadgeTone.danger,
                    icon: Icons.person_off_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: AppStrings.sectionRegionalBranches),
              const SizedBox(height: 10),
              const _RegionalBranchesCard(),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardFilterHeader extends StatelessWidget {
  const _DashboardFilterHeader({
    required this.summary,
    required this.onPickRange,
    required this.onReset,
  });

  final DashboardSummary summary;
  final VoidCallback onPickRange;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAllTime =
        summary.startDate == '2020-01-01' && summary.endDate == '2030-12-31';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dashboardHeader,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isAllTime
                ? 'Periode: Semua data historis s.d. saat ini'
                : 'Periode: ${summary.startDate} s.d. ${summary.endDate}',
            style: context.monoStyle.copyWith(color: colors.accent),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPickRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: const Text(AppStrings.filterDateRange),
              ),
              if (!isAllTime)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text(AppStrings.resetFilter),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.textStyles.titleMedium);
  }
}

class _ApplicantHeroCard extends StatelessWidget {
  const _ApplicantHeroCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.labelActiveApplicants,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onAccent.withValues(alpha: 0.85),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.onAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${AppStrings.labelSchedules}: ${summary.totalInterview}',
                  style: context.monoStyle.copyWith(color: colors.onAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary.totalActiveApplicants.toString(),
            style: context.textStyles.headlineMedium?.copyWith(
              color: colors.onAccent,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SubPoolPill(
                  label: AppStrings.labelNewComer,
                  value: summary.totalNewComer.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SubPoolPill(
                  label: AppStrings.labelExisting,
                  value: summary.totalExisting.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubPoolPill extends StatelessWidget {
  const _SubPoolPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.onAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.onAccent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.monoStyle.copyWith(
              color: colors.onAccent,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final HkBadgeTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accentColor = switch (tone) {
      HkBadgeTone.success => colors.success,
      HkBadgeTone.warning => colors.warning,
      HkBadgeTone.danger => colors.danger,
      HkBadgeTone.warm => colors.brandWarm,
      HkBadgeTone.accent => colors.accent,
      HkBadgeTone.neutral => colors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.monoStyle.copyWith(fontSize: 20, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _RegionalBranchesCard extends StatelessWidget {
  const _RegionalBranchesCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: DashboardSummary.regionalBranches
            .map(
              (branch) =>
                  HkStatusBadge(label: branch, tone: HkBadgeTone.accent),
            )
            .toList(),
      ),
    );
  }
}

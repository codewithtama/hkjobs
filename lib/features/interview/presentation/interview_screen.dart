import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../domain/interview_models.dart';
import 'interview_controller.dart';
import 'widgets/interview_evaluation_sheet.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScheduleQr(InterviewScheduleItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HkQrPreviewSheet(
        title: 'QR Kehadiran Interview',
        subtitle: '${item.code} • ${item.vacancyCode}',
        imageUrl: item.qrCodeUrl,
      ),
    );
  }

  void _openScheduleParticipants(InterviewScheduleItem item) {
    context.push(
      '/interview/participants/${item.id}?code=${item.code}&vacancy=${item.vacancyCode}',
    );
  }

  Future<void> _openEvaluationSheet(InterviewCandidateItem candidate) async {
    final saved = await InterviewEvaluationSheet.show(
      context,
      candidate: candidate,
    );
    if (saved == true && mounted) {
      await ref.read(interviewControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(interviewControllerProvider);
    final activeTab =
        asyncState.valueOrNull?.activeTab ?? InterviewSubTab.schedules;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await context.push<bool>('/management/create-interview');
          if (res == true && mounted) {
            await ref.read(interviewControllerProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Jadwal'),
      ),
      body: Column(
        children: [
          Container(
            color: context.colors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: InterviewSubTab.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = InterviewSubTab.values[index];
                      return ChoiceChip(
                        label: Text(tab.label),
                        selected: tab == activeTab,
                        onSelected: (_) => ref
                            .read(interviewControllerProvider.notifier)
                            .selectTab(tab),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                HkSearchField(
                  controller: _searchController,
                  onSubmitted: (q) => ref
                      .read(interviewControllerProvider.notifier)
                      .updateSearch(q),
                  onClear: () {
                    _searchController.clear();
                    ref
                        .read(interviewControllerProvider.notifier)
                        .updateSearch('');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncState.when(
              loading: () =>
                  const HkLoadingView(message: AppStrings.loadingInterviews),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.read(interviewControllerProvider.notifier).refresh(),
                );
              },
              data: (viewState) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(interviewControllerProvider.notifier).refresh(),
                  child: viewState.activeTab == InterviewSubTab.schedules
                      ? _buildScheduleList(viewState.schedules)
                      : _buildCandidateList(viewState.candidates),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<InterviewScheduleItem> items) {
    if (items.isEmpty) return const HkEmptyView();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ScheduleCard(
            item: item,
            onShowQr: () => _openScheduleQr(item),
            onViewParticipants: () => _openScheduleParticipants(item),
          ),
        );
      },
    );
  }

  Widget _buildCandidateList(List<InterviewCandidateItem> items) {
    if (items.isEmpty) return const HkEmptyView();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CandidateCard(
            item: item,
            onEvaluate: () => _openEvaluationSheet(item),
          ),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.item,
    required this.onShowQr,
    required this.onViewParticipants,
  });

  final InterviewScheduleItem item;
  final VoidCallback onShowQr;
  final VoidCallback onViewParticipants;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final countLabel = item.candidateCount > 0
        ? '${item.candidateCount} Peserta'
        : 'Lihat Peserta';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onViewParticipants,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.code,
                    style: context.monoStyle.copyWith(
                      color: colors.accent,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                HkStatusBadge.fromStatusText(item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.vacancyCode,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Jadwal: ${item.date} (${item.timeRange})',
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Kuota maks: ${item.maxQuota} • Dikonfirmasi: ${item.confirmedCount}',
              style: context.textStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onShowQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('QR Kehadiran'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onViewParticipants,
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: Text(countLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.item,
    required this.onEvaluate,
  });

  final InterviewCandidateItem item;
  final VoidCallback onEvaluate;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.fullName,
                  style: context.textStyles.titleMedium,
                ),
              ),
              HkStatusBadge.fromStatusText(item.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.interviewCode} • ${item.vacancyCode}',
            style: context.monoStyle.copyWith(color: colors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'HP: ${item.phone} • Kota: ${item.city}',
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Hadir: ${item.attendanceTime} • Penilai: ${item.interviewerName}',
            style: context.textStyles.bodySmall,
          ),
          if (item.reason != '-' && item.reason != 'None') ...[
            const SizedBox(height: 4),
            Text(
              'Catatan: ${item.reason}',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.danger,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onEvaluate,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Nilai interview'),
            ),
          ),
        ],
      ),
    );
  }
}



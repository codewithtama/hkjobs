import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_filter_sheet.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../../../core/widgets/hk_whatsapp_button.dart';
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

  Future<void> _openFilterSheet(InterviewViewState? viewState) async {
    if (viewState == null) return;
    final result = await showHkFilterBottomSheet(
      context: context,
      initial: viewState.filterData,
      showBranch: true,
      showDateRange: true,
      showExperience: false,
      showVacancy: true,
      showInterview: true,
      showPlacement: false,
      showPosition: true,
      showCity: true,
      showGender: true,
      availableInterviews: viewState.availableInterviewCodes,
      availableVacancies: viewState.availableVacancyCodes,
      availableCities: viewState.availableCities,
    );
    if (result != null) {
      await ref.read(interviewControllerProvider.notifier).updateFilter(result);
    }
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
    final viewState = asyncState.valueOrNull;
    final activeTab =
        viewState?.activeTab ?? InterviewSubTab.schedules;

    return Scaffold(
      floatingActionButton: activeTab == InterviewSubTab.schedules
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res =
                    await context.push<bool>('/management/create-interview');
                if (res == true && mounted) {
                  await ref
                      .read(interviewControllerProvider.notifier)
                      .refresh();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Jadwal'),
            )
          : null,
      bottomNavigationBar: (viewState != null && viewState.totalCount > 0)
          ? HkPaginationBar(
              currentPage: viewState.page,
              totalCount: viewState.totalCount,
              pageSize: viewState.pageSize,
              onPageChanged: (p) => ref
                  .read(interviewControllerProvider.notifier)
                  .goToPage(p),
            )
          : null,
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
                if (activeTab != InterviewSubTab.schedules &&
                    asyncState.valueOrNull != null &&
                    asyncState
                        .valueOrNull!
                        .availableInterviewCodes
                        .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: const Text('Semua Jadwal'),
                            selected:
                                asyncState
                                        .valueOrNull!
                                        .selectedInterviewFilter ==
                                    null ||
                                asyncState
                                    .valueOrNull!
                                    .selectedInterviewFilter!
                                    .isEmpty,
                            onSelected: (_) => ref
                                .read(interviewControllerProvider.notifier)
                                .selectInterviewFilter(null),
                          ),
                        ),
                        ...asyncState.valueOrNull!.availableInterviewCodes.map((
                          code,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(code),
                              selected:
                                  asyncState
                                      .valueOrNull!
                                      .selectedInterviewFilter ==
                                  code,
                              onSelected: (_) => ref
                                  .read(interviewControllerProvider.notifier)
                                  .selectInterviewFilter(
                                    asyncState
                                                .valueOrNull!
                                                .selectedInterviewFilter ==
                                            code
                                        ? null
                                        : code,
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: HkSearchField(
                        controller: _searchController,
                        hintText: 'Cari kode, nama kandidat, atau kota...',
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
                    ),
                    const SizedBox(width: 8),
                    HkFilterByButton(
                      count:
                          asyncState.valueOrNull?.filterData.activeCount ?? 0,
                      onPressed: () => _openFilterSheet(asyncState.valueOrNull),
                    ),
                  ],
                ),
                if (asyncState.valueOrNull != null)
                  HkActiveFilterChips(
                    filterData: asyncState.valueOrNull!.filterData,
                    onFilterChanged: (f) => ref
                        .read(interviewControllerProvider.notifier)
                        .updateFilter(f),
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
                  onRefresh: () => ref
                      .read(interviewControllerProvider.notifier)
                      .refresh(),
                  child: viewState.activeTab == InterviewSubTab.schedules
                      ? _buildScheduleList(viewState.filteredSchedules)
                      : _buildCandidateList(viewState),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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

  Widget _buildCandidateList(InterviewViewState viewState) {
    final grouped = viewState.candidatesByInterview;
    if (grouped.isEmpty) return const HkEmptyView();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final entry = grouped.entries.elementAt(groupIndex);
        final interviewCode = entry.key;
        final candidates = entry.value;
        final vacancyCode = candidates.isNotEmpty
            ? candidates.first.vacancyCode
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InterviewGroupHeader(
                interviewCode: interviewCode,
                vacancyCode: vacancyCode,
                count: candidates.length,
              ),
              const SizedBox(height: 10),
              ...candidates.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CandidateCard(
                    item: item,
                    onEvaluate: () => _openEvaluationSheet(item),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InterviewGroupHeader extends StatelessWidget {
  const _InterviewGroupHeader({
    required this.interviewCode,
    required this.vacancyCode,
    required this.count,
  });

  final String interviewCode;
  final String vacancyCode;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note_rounded, size: 20, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interviewCode,
                  style: context.monoStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                    fontSize: 13.5,
                  ),
                ),
                if (vacancyCode.isNotEmpty && vacancyCode != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    vacancyCode,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Kandidat',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
        : 'Lihat Peserta (0)';

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
            Text(item.vacancyCode, style: context.textStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Jadwal: ${item.date} (${item.timeRange})',
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Kuota maks: ${item.maxQuota} • Dikonfirmasi: ${item.confirmedCount} orang',
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
  const _CandidateCard({required this.item, required this.onEvaluate});

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
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (item.interviewCode.isNotEmpty && item.interviewCode != '-')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    item.interviewCode,
                    style: context.monoStyle.copyWith(
                      color: colors.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (item.vacancyCode.isNotEmpty && item.vacancyCode != '-')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    item.vacancyCode,
                    style: context.monoStyle.copyWith(
                      color: colors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
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
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              HkWhatsAppButton(
                phone: item.phone,
                candidateName: item.fullName,
                contextDescription: 'jadwal interview ${item.interviewCode}',
              ),
              FilledButton.icon(
                onPressed: onEvaluate,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Nilai interview'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

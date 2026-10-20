import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';
import 'interview_controller.dart';

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

  Future<void> _openEvaluationSheet(InterviewCandidateItem candidate) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _InterviewEvaluationSheet(candidate: candidate),
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
  });

  final InterviewScheduleItem item;
  final VoidCallback onShowQr;

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
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onShowQr,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('QR Kehadiran'),
            ),
          ),
        ],
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

class _InterviewEvaluationSheet extends ConsumerStatefulWidget {
  const _InterviewEvaluationSheet({required this.candidate});

  final InterviewCandidateItem candidate;

  @override
  ConsumerState<_InterviewEvaluationSheet> createState() =>
      _InterviewEvaluationSheetState();
}

class _InterviewEvaluationSheetState
    extends ConsumerState<_InterviewEvaluationSheet> {
  InterviewEvaluationRubric _rubric = const InterviewEvaluationRubric();
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final repo = ref.read(interviewRepositoryProvider);
    final res = await repo.submitEvaluation(
      userAdvertId: widget.candidate.userAdvertId,
      rubric: _rubric,
      failureReason: _reasonController.text,
    );
    if (!mounted) return;
    switch (res) {
      case Success<void>():
        Navigator.of(context).pop(true);
      case Failure<void>(:final error):
        setState(() {
          _submitting = false;
          _errorText = error.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final passed = _rubric.isPassed;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              AppStrings.evaluateCandidateTitle,
              style: context.textStyles.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.candidate.fullName} (${widget.candidate.interviewCode})',
              style: context.monoStyle.copyWith(color: colors.accent),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: passed ? colors.successMuted : colors.dangerMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passed
                              ? 'Status: LOLOS (Passed)'
                              : 'Status: GAGAL (Failed)',
                          style: context.textStyles.titleMedium?.copyWith(
                            color: passed ? colors.success : colors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.passingThresholdNote,
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_rubric.totalScore}',
                    style: context.monoStyle.copyWith(
                      fontSize: 28,
                      color: passed ? colors.success : colors.danger,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _VerificationSwitchRow(
              label: 'Verifikasi data diri (+10 / -25)',
              value: _rubric.dataDiriSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(dataDiriSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi fisik (+10 / -25)',
              value: _rubric.fisikSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(fisikSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Pengalaman kerja ada (+5 / 0)',
              value: _rubric.pengalamanAda,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(pengalamanAda: v)),
            ),
            _VerificationSwitchRow(
              label: 'Pengalaman sesuai posisi (+5 / 0)',
              value: _rubric.pengalamanSesuai,
              onChanged: (v) => setState(
                () => _rubric = _rubric.copyWith(pengalamanSesuai: v),
              ),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi ijazah asli (+5 / 0)',
              value: _rubric.ijazahSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(ijazahSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi SKCK (+5 / 0)',
              value: _rubric.skckSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(skckSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi SIO (+5 / 0)',
              value: _rubric.sioSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(sioSesuai: v)),
            ),
            const Divider(height: 24),
            _RateSelectorRow(
              title: 'Skor penampilan / Grooming',
              selectedValue: _rubric.groomingRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(groomingRate: v)),
            ),
            const SizedBox(height: 12),
            _RateSelectorRow(
              title: 'Skor intelejensi',
              selectedValue: _rubric.intelejenRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(intelejenRate: v)),
            ),
            const SizedBox(height: 12),
            _RateSelectorRow(
              title: 'Skor komunikasi',
              selectedValue: _rubric.komunikasiRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(komunikasiRate: v)),
            ),
            if (!passed) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan gagal interview (Wajib jika skor ≤ 64)',
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.submitEvaluationButton),
            ),
          ],
        );
      },
    );
  }
}

class _VerificationSwitchRow extends StatelessWidget {
  const _VerificationSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.textStyles.bodyMedium),
      subtitle: Text(
        value ? 'Sesuai / Ada' : 'Tidak sesuai / Tidak ada',
        style: context.textStyles.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _RateSelectorRow extends StatelessWidget {
  const _RateSelectorRow({
    required this.title,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final int selectedValue;
  final ValueChanged<int> onSelected;

  static const List<int> _options = <int>[2, 4, 6, 8, 10];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: _options
              .map(
                (score) => ChoiceChip(
                  label: Text('+$score'),
                  selected: selectedValue == score,
                  onSelected: (_) => onSelected(score),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

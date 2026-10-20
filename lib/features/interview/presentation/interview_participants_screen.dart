import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../../recruitment/presentation/widgets/applicant_profile_bottom_sheet.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';
import 'widgets/interview_evaluation_sheet.dart';

final interviewParticipantsProvider = FutureProvider.autoDispose
    .family<List<InterviewCandidateItem>, (String, String, String)>(
        (ref, params) async {
  final (interviewId, vacancyCode, interviewCode) = params;
  final repo = ref.watch(interviewRepositoryProvider);
  final res = await repo.fetchInterviewParticipants(
    interviewId,
    vacancyCode: vacancyCode,
    interviewCode: interviewCode,
  );
  switch (res) {
    case Success<PaginatedList<InterviewCandidateItem>>(:final data):
      return data.items;
    case Failure<PaginatedList<InterviewCandidateItem>>(:final error):
      throw error;
  }
});

class InterviewParticipantsScreen extends ConsumerStatefulWidget {
  const InterviewParticipantsScreen({
    required this.interviewId,
    this.interviewCode,
    this.vacancyCode,
    super.key,
  });

  final String interviewId;
  final String? interviewCode;
  final String? vacancyCode;

  @override
  ConsumerState<InterviewParticipantsScreen> createState() =>
      _InterviewParticipantsScreenState();
}

class _InterviewParticipantsScreenState
    extends ConsumerState<InterviewParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  (String, String, String) get _params => (
        widget.interviewId,
        widget.vacancyCode ?? '',
        widget.interviewCode ?? '',
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEvaluationSheet(InterviewCandidateItem candidate) async {
    final saved = await InterviewEvaluationSheet.show(context, candidate: candidate);
    if (saved == true && mounted) {
      ref.invalidate(interviewParticipantsProvider(_params));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(interviewParticipantsProvider(_params));
    final title = widget.interviewCode != null
        ? '${FormStrings.interviewParticipantsTitle}: ${widget.interviewCode}'
        : FormStrings.interviewParticipantsTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Container(
            color: context.colors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: HkSearchField(
              controller: _searchController,
              hintText: 'Cari nama atau kota kandidat...',
              onSubmitted: (q) =>
                  setState(() => _searchQuery = q.trim().toLowerCase()),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncData.when(
              loading: () => const HkLoadingView(
                message: FormStrings.loadingInterviewParticipants,
              ),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.invalidate(interviewParticipantsProvider(_params)),
                );
              },
              data: (items) {
                final filtered = items.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.fullName.toLowerCase().contains(_searchQuery) ||
                      e.city.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(interviewParticipantsProvider(_params));
                    },
                    child: ListView(
                      children: const [
                        HkEmptyView(
                          title: 'Belum ada peserta interview',
                          subtitle:
                              'Tidak ada kandidat yang terdaftar pada jadwal interview ini.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(interviewParticipantsProvider(_params));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ScheduleCandidateCard(
                          item: item,
                          onInspectProfile: () =>
                              ApplicantProfileBottomSheet.show(
                            context,
                            applicantId: item.applicantId,
                            initialName: item.fullName,
                          ),
                          onEvaluate: () => _openEvaluationSheet(item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCandidateCard extends StatelessWidget {
  const _ScheduleCandidateCard({
    required this.item,
    required this.onInspectProfile,
    required this.onEvaluate,
  });

  final InterviewCandidateItem item;
  final VoidCallback onInspectProfile;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPendingEvaluation = item.status.toLowerCase().contains('process') ||
        item.status.toLowerCase().contains('konfirmasi') ||
        item.status == '-';

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
          if (item.reason != '-' && item.reason != 'None' && item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.dangerMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: ${item.reason}',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.danger,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onInspectProfile,
                icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                label: const Text(AppStrings.detailApplicantButton),
              ),
              FilledButton.icon(
                onPressed: onEvaluate,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(
                  isPendingEvaluation ? 'Nilai interview' : 'Ubah nilai',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

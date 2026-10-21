import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../../../core/widgets/hk_whatsapp_button.dart';
import '../../recruitment/presentation/widgets/applicant_profile_bottom_sheet.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';
import 'widgets/interview_evaluation_sheet.dart';

typedef InterviewParticipantsParams = ({
  String interviewId,
  String vacancyCode,
  String interviewCode,
  int page,
  String searchQuery,
});

final interviewParticipantsProvider = FutureProvider.autoDispose
    .family<PaginatedList<InterviewCandidateItem>, InterviewParticipantsParams>(
      (ref, params) async {
        final repo = ref.watch(interviewRepositoryProvider);
        final res = await repo.fetchInterviewParticipants(
          params.interviewId,
          vacancyCode: params.vacancyCode,
          interviewCode: params.interviewCode,
          page: params.page,
          limit: 20,
          searchQuery: params.searchQuery,
        );
        switch (res) {
          case Success<PaginatedList<InterviewCandidateItem>>(:final data):
            return data;
          case Failure<PaginatedList<InterviewCandidateItem>>(:final error):
            throw error;
        }
      },
    );

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
  String _statusFilter = 'Semua';
  int _page = 1;

  InterviewParticipantsParams get _params => (
    interviewId: widget.interviewId,
    vacancyCode: widget.vacancyCode ?? '',
    interviewCode: widget.interviewCode ?? '',
    page: _page,
    searchQuery: _searchQuery,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEvaluationSheet(InterviewCandidateItem candidate) async {
    final saved = await InterviewEvaluationSheet.show(
      context,
      candidate: candidate,
    );
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
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            color: context.colors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                          'Semua',
                          'Konfirmasi',
                          'Passed',
                          'Failed',
                          'Batal',
                        ].map((status) {
                          final label = switch (status) {
                            'Passed' => 'Lolos',
                            'Failed' => 'Gagal',
                            _ => status,
                          };
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                HkSearchField(
                  controller: _searchController,
                  hintText: 'Cari nama atau kota kandidat...',
                  onSubmitted: (q) => setState(() {
                    _searchQuery = q.trim();
                    _page = 1;
                  }),
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _page = 1;
                    });
                  },
                ),
              ],
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
              data: (data) {
                final filteredItems = _statusFilter == 'Semua'
                    ? data.items
                    : data.items.where((i) {
                        final s = i.status.toLowerCase();
                        if (_statusFilter == 'Passed') {
                          return s.contains('pass') || s.contains('lolos');
                        }
                        if (_statusFilter == 'Failed') {
                          return s.contains('fail') ||
                              s.contains('gagal') ||
                              s.contains('tidak');
                        }
                        if (_statusFilter == 'Batal') {
                          return s.contains('batal') || s.contains('cancel');
                        }
                        if (_statusFilter == 'Konfirmasi') {
                          return s.contains('konfirm');
                        }
                        return true;
                      }).toList();

                if (filteredItems.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(interviewParticipantsProvider(_params));
                    },
                    child: ListView(
                      children: const [
                        HkEmptyView(
                          title: 'Belum ada peserta interview',
                          subtitle:
                              'Tidak ada kandidat yang sesuai dengan filter atau kata kunci.',
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(
                            interviewParticipantsProvider(_params),
                          );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
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
                      ),
                    ),
                    if (data.totalCount > 0)
                      HkPaginationBar(
                        currentPage: data.page,
                        totalCount: data.totalCount,
                        pageSize: data.pageSize,
                        onPageChanged: (p) => setState(() => _page = p),
                      ),
                  ],
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
    final isPendingEvaluation =
        item.status.toLowerCase().contains('process') ||
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
          if (item.reason != '-' &&
              item.reason != 'None' &&
              item.reason.isNotEmpty) ...[
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
              HkWhatsAppButton(
                phone: item.phone,
                candidateName: item.fullName,
                contextDescription: 'jadwal interview ${item.interviewCode}',
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

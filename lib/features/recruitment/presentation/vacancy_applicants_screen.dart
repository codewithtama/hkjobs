import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/recruitment_repository.dart';
import '../domain/recruitment_models.dart';
import 'widgets/applicant_profile_bottom_sheet.dart';
import 'widgets/review_application_dialog.dart';

final vacancyApplicantsProvider = FutureProvider.autoDispose
    .family<List<VacancyApplicationItem>, String>((ref, vacancyId) async {
  final repo = ref.watch(recruitmentRepositoryProvider);
  final res = await repo.fetchVacancyApplicants(vacancyId);
  switch (res) {
    case Success<PaginatedList<VacancyApplicationItem>>(:final data):
      return data.items;
    case Failure<PaginatedList<VacancyApplicationItem>>(:final error):
      throw error;
  }
});

class VacancyApplicantsScreen extends ConsumerStatefulWidget {
  const VacancyApplicantsScreen({
    required this.vacancyId,
    this.vacancyCode,
    super.key,
  });

  final String vacancyId;
  final String? vacancyCode;

  @override
  ConsumerState<VacancyApplicantsScreen> createState() =>
      _VacancyApplicantsScreenState();
}

class _VacancyApplicantsScreenState
    extends ConsumerState<VacancyApplicantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openReviewDialog(VacancyApplicationItem item) async {
    final updated = await ReviewApplicationDialog.show(context, item: item);
    if (updated == true && mounted) {
      ref.invalidate(vacancyApplicantsProvider(widget.vacancyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(vacancyApplicantsProvider(widget.vacancyId));
    final title = widget.vacancyCode != null
        ? '${FormStrings.vacancyApplicantsTitle}: ${widget.vacancyCode}'
        : FormStrings.vacancyApplicantsTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Laporan Lowongan (PDF)',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              final pdfUrl =
                  '${ApiEndpoints.baseUrl}advertisement/pdf/${widget.vacancyId}';
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: context.colors.danger,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Laporan PDF Lowongan')),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dokumen laporan rekapitulasi funnel pelamar resmi untuk lowongan ${widget.vacancyCode ?? widget.vacancyId}:',
                        style: context.textStyles.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        pdfUrl,
                        style: context.monoStyle.copyWith(
                          color: context.colors.accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: context.colors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: HkSearchField(
              controller: _searchController,
              hintText: 'Cari nama atau NIK pelamar...',
              onSubmitted: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
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
                message: FormStrings.loadingVacancyApplicants,
              ),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.invalidate(vacancyApplicantsProvider(widget.vacancyId)),
                );
              },
              data: (items) {
                final filtered = items.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.fullName.toLowerCase().contains(_searchQuery) ||
                      e.nik.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(vacancyApplicantsProvider(widget.vacancyId));
                    },
                    child: ListView(
                      children: const [
                        HkEmptyView(
                          title: 'Belum ada pelamar',
                          subtitle:
                              'Tidak ada pelamar yang terdaftar untuk lowongan ini.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(vacancyApplicantsProvider(widget.vacancyId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VacancyApplicantCard(
                          item: item,
                          onInspectProfile: () =>
                              ApplicantProfileBottomSheet.show(
                            context,
                            applicantId: item.applicantId,
                            initialName: item.fullName,
                          ),
                          onReview: () => _openReviewDialog(item),
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

class _VacancyApplicantCard extends StatelessWidget {
  const _VacancyApplicantCard({
    required this.item,
    required this.onInspectProfile,
    required this.onReview,
  });

  final VacancyApplicationItem item;
  final VoidCallback onInspectProfile;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPendingReview = item.statusText.toLowerCase().contains('process') ||
        item.statusText.toLowerCase().contains('diproses') ||
        item.statusText == '-';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.fullName,
                  style: context.textStyles.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              HkStatusBadge.fromStatusText(item.statusText),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NIK: ${item.nik} • HP: ${item.phone}',
            style: context.monoStyle.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.lastPosition} (${item.experience})',
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.gender}, ${item.heightCm} cm / ${item.weightKg} kg • ${item.education} • ${item.city}',
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Tgl lamar: ${item.applyDate}',
            style: context.textStyles.bodySmall?.copyWith(color: colors.textMuted),
          ),
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
              if (isPendingReview)
                FilledButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text(AppStrings.reviewApplicantButton),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

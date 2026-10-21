import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../../../core/widgets/hk_whatsapp_button.dart';
import '../data/recruitment_repository.dart';
import '../domain/recruitment_models.dart';
import 'widgets/applicant_profile_bottom_sheet.dart';
import 'widgets/review_application_dialog.dart';

typedef VacancyApplicantsParams = ({
  String vacancyId,
  String vacancyCode,
  int page,
  String searchQuery,
});

final vacancyApplicantsProvider = FutureProvider.autoDispose
    .family<PaginatedList<VacancyApplicationItem>, VacancyApplicantsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(recruitmentRepositoryProvider);
      final res = await repo.fetchVacancyApplicants(
        params.vacancyId,
        vacancyCode: params.vacancyCode,
        page: params.page,
        limit: 20,
        searchQuery: params.searchQuery,
      );
      switch (res) {
        case Success<PaginatedList<VacancyApplicationItem>>(:final data):
          return data;
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
  String _statusFilter = 'Semua';
  int _page = 1;

  VacancyApplicantsParams get _params => (
    vacancyId: widget.vacancyId,
    vacancyCode: widget.vacancyCode ?? '',
    page: _page,
    searchQuery: _searchQuery,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openReviewDialog(VacancyApplicationItem item) async {
    final updated = await ReviewApplicationDialog.show(context, item: item);
    if (updated == true && mounted) {
      ref.invalidate(vacancyApplicantsProvider(_params));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(vacancyApplicantsProvider(_params));
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
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        ['Semua', 'On Process', 'Approved', 'Not Approved'].map(
                          (status) {
                            final label = switch (status) {
                              'On Process' => 'Diproses',
                              'Approved' => 'Diterima',
                              'Not Approved' => 'Ditolak',
                              _ => 'Semua',
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
                          },
                        ).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                HkSearchField(
                  controller: _searchController,
                  hintText: 'Cari nama atau NIK pelamar...',
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
                message: FormStrings.loadingVacancyApplicants,
              ),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.invalidate(vacancyApplicantsProvider(_params)),
                );
              },
              data: (data) {
                final filteredItems = _statusFilter == 'Semua'
                    ? data.items
                    : data.items.where((i) {
                        final s = i.statusText.toLowerCase();
                        if (_statusFilter == 'On Process') {
                          return s.contains('process');
                        }
                        if (_statusFilter == 'Approved') {
                          return s.contains('approve') || s.contains('terima');
                        }
                        if (_statusFilter == 'Not Approved') {
                          return s.contains('not') || s.contains('tolak');
                        }
                        return true;
                      }).toList();

                if (filteredItems.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(vacancyApplicantsProvider(_params));
                    },
                    child: ListView(
                      children: const [
                        HkEmptyView(
                          title: 'Belum ada pelamar',
                          subtitle:
                              'Tidak ada pelamar yang sesuai dengan filter atau kata kunci.',
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
                          ref.invalidate(vacancyApplicantsProvider(_params));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
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
    final isPendingReview =
        item.statusText.toLowerCase().contains('process') ||
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
          if (item.vacancyCode.isNotEmpty) ...[
            Text(
              item.vacancyCode,
              style: context.monoStyle.copyWith(
                color: colors.accent,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
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
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
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
              HkWhatsAppButton(
                phone: item.phone,
                candidateName: item.fullName,
                contextDescription:
                    'lamaran pekerjaan di lowongan ${item.lastPosition}',
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

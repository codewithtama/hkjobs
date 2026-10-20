import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../../../core/widgets/hk_whatsapp_button.dart';
import '../domain/recruitment_models.dart';
import 'recruitment_controller.dart';
import 'widgets/applicant_profile_bottom_sheet.dart';
import 'widgets/review_application_dialog.dart';

class RecruitmentScreen extends ConsumerStatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  ConsumerState<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends ConsumerState<RecruitmentScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQrSheet(JobVacancyItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HkQrPreviewSheet(
        title: 'QR Lowongan Kerja',
        subtitle: item.code,
        imageUrl: item.qrCodeUrl,
      ),
    );
  }

  void _openApplicantDetailSheet(String applicantId, String initialName) {
    ApplicantProfileBottomSheet.show(
      context,
      applicantId: applicantId,
      initialName: initialName,
    );
  }

  Future<void> _openReviewDialog(VacancyApplicationItem item) async {
    final updated = await ReviewApplicationDialog.show(context, item: item);
    if (updated == true && mounted) {
      await ref.read(recruitmentControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(recruitmentControllerProvider);
    final activeTab =
        asyncState.valueOrNull?.activeTab ?? RecruitmentSubTab.vacancies;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await context.push<bool>('/management/create-vacancy');
          if (res == true && mounted) {
            await ref.read(recruitmentControllerProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Lowongan'),
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
                    itemCount: RecruitmentSubTab.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = RecruitmentSubTab.values[index];
                      final selected = tab == activeTab;
                      return ChoiceChip(
                        label: Text(tab.label),
                        selected: selected,
                        onSelected: (_) {
                          ref
                              .read(recruitmentControllerProvider.notifier)
                              .selectTab(tab);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                HkSearchField(
                  controller: _searchController,
                  onSubmitted: (q) => ref
                      .read(recruitmentControllerProvider.notifier)
                      .updateSearch(q),
                  onClear: () {
                    _searchController.clear();
                    ref
                        .read(recruitmentControllerProvider.notifier)
                        .updateSearch('');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncState.when(
              loading: () => const HkLoadingView(
                message: AppStrings.loadingApplicants,
              ),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.read(recruitmentControllerProvider.notifier).refresh(),
                );
              },
              data: (viewState) {
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(recruitmentControllerProvider.notifier)
                            .refresh(),
                        child: _buildListContent(viewState),
                      ),
                    ),
                    if (viewState.totalCount > 0)
                      HkPaginationBar(
                        currentPage: viewState.page,
                        totalCount: viewState.totalCount,
                        pageSize: viewState.pageSize,
                        onPageChanged: (p) => ref
                            .read(recruitmentControllerProvider.notifier)
                            .goToPage(p),
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

  Widget _buildListContent(RecruitmentViewState viewState) {
    switch (viewState.activeTab) {
      case RecruitmentSubTab.vacancies:
        if (viewState.vacancies.isEmpty) return const HkEmptyView();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewState.vacancies.length,
          itemBuilder: (context, index) {
            final item = viewState.vacancies[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VacancyCard(
                item: item,
                onViewQr: () => _openQrSheet(item),
                onViewApplicants: () => context.push(
                  '/recruitment/applicants/${item.id}?code=${item.code}',
                ),
              ),
            );
          },
        );

      case RecruitmentSubTab.onProcess:
      case RecruitmentSubTab.approved:
      case RecruitmentSubTab.rejected:
        if (viewState.applications.isEmpty) return const HkEmptyView();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewState.applications.length,
          itemBuilder: (context, index) {
            final item = viewState.applications[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationCard(
                item: item,
                onInspectProfile: () => _openApplicantDetailSheet(
                  item.applicantId,
                  item.fullName,
                ),
                onReview: viewState.activeTab == RecruitmentSubTab.onProcess
                    ? () => _openReviewDialog(item)
                    : null,
              ),
            );
          },
        );

      case RecruitmentSubTab.newComers:
      case RecruitmentSubTab.existing:
        if (viewState.masterApplicants.isEmpty) return const HkEmptyView();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewState.masterApplicants.length,
          itemBuilder: (context, index) {
            final item = viewState.masterApplicants[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MasterApplicantCard(
                item: item,
                onInspect: () => _openApplicantDetailSheet(
                  item.applicantId,
                  item.fullName,
                ),
              ),
            );
          },
        );
    }
  }
}

class _VacancyCard extends StatelessWidget {
  const _VacancyCard({
    required this.item,
    required this.onViewQr,
    required this.onViewApplicants,
  });

  final JobVacancyItem item;
  final VoidCallback onViewQr;
  final VoidCallback onViewApplicants;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onViewApplicants,
      borderRadius: BorderRadius.circular(14),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.code,
                    style: context.monoStyle.copyWith(
                      fontSize: 13.5,
                      color: colors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HkStatusBadge.fromStatusText(item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Periode tayang: ${item.period}',
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Dibuat pada: ${item.createdAt} • Pelamar: ${item.applicantSummary}',
              style: context.textStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewQr,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(AppStrings.viewQrButton),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onViewApplicants,
                  icon: const Icon(Icons.people_outline_rounded, size: 18),
                  label: Text('Lihat Pelamar (${item.applicantCount})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.item,
    required this.onInspectProfile,
    this.onReview,
  });

  final VacancyApplicationItem item;
  final VoidCallback onInspectProfile;
  final VoidCallback? onReview;

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
                contextDescription: 'lamaran posisi ${item.lastPosition}',
              ),
              if (onReview != null)
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

class _MasterApplicantCard extends StatelessWidget {
  const _MasterApplicantCard({
    required this.item,
    required this.onInspect,
  });

  final MasterApplicantItem item;
  final VoidCallback onInspect;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.fullName, style: context.textStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'ID #${item.applicantId} • ${item.experienceOrDate}',
                  style: context.textStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                HkStatusBadge.fromStatusText(item.status),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onInspect,
            child: const Text(AppStrings.detailApplicantButton),
          ),
        ],
      ),
    );
  }
}

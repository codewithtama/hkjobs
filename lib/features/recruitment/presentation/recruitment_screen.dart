import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/recruitment_repository.dart';
import '../domain/recruitment_models.dart';
import 'recruitment_controller.dart';

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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ApplicantProfileBottomSheet(
        applicantId: applicantId,
        initialName: initialName,
      ),
    );
  }

  Future<void> _openReviewDialog(VacancyApplicationItem item) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewApplicationDialog(item: item),
    );
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
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(recruitmentControllerProvider.notifier).refresh(),
                  child: _buildListContent(viewState),
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
  });

  final JobVacancyItem item;
  final VoidCallback onViewQr;

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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onViewQr,
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text(AppStrings.viewQrButton),
            ),
          ),
        ],
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

class _ApplicantProfileBottomSheet extends ConsumerWidget {
  const _ApplicantProfileBottomSheet({
    required this.applicantId,
    required this.initialName,
  });

  final String applicantId;
  final String initialName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(recruitmentRepositoryProvider);
    final colors = context.colors;

    return FutureBuilder<Result<ApplicantFullProfile>>(
      future: repo.fetchApplicantProfile(applicantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 360,
            child: HkLoadingView(message: AppStrings.loadingApplicantDetail),
          );
        }

        final result = snapshot.data!;
        return switch (result) {
          Failure<ApplicantFullProfile>(:final error) => SizedBox(
              height: 320,
              child: HkErrorView(
                message: error.message,
                onRetry: () => Navigator.of(context).pop(),
              ),
            ),
          Success<ApplicantFullProfile>(:final data) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.fullName,
                            style: context.textStyles.titleLarge,
                          ),
                        ),
                        HkStatusBadge.fromStatusText(data.statusActive),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIK: ${data.nik} • ID #${data.id}',
                      style: context.monoStyle.copyWith(color: colors.accent),
                    ),
                    const SizedBox(height: 16),
                    _ProfileInfoGrid(profile: data),
                    const SizedBox(height: 20),
                    Text(
                      'Berkas dokumen terunggah (${data.documents.length})',
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (data.documents.isEmpty)
                      Text(
                        'Belum ada dokumen terunggah.',
                        style: context.textStyles.bodySmall,
                      )
                    else
                      ...data.documents.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DocumentPreviewCard(
                            label: entry.key,
                            imageUrl: entry.value,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        };
      },
    );
  }
}

class _ProfileInfoGrid extends StatelessWidget {
  const _ProfileInfoGrid({required this.profile});

  final ApplicantFullProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <(String, String)>[
      ('No. Telepon', profile.phone),
      ('Email', profile.email),
      ('Tempat, Tgl Lahir', '${profile.birthPlace}, ${profile.birthDate}'),
      ('Jenis Kelamin', profile.gender),
      ('Tinggi / Berat', '${profile.heightCm} cm / ${profile.weightKg} kg'),
      ('Pendidikan', profile.education),
      ('Posisi Dilamar', profile.positionName),
      ('Pengalaman', profile.workExperience),
      ('Status Kawin', profile.maritalStatus),
      ('Tato / Tindik', '${profile.hasTattoo} / ${profile.hasPiercing}'),
      (
        'Domisili',
        '${profile.address}, ${profile.district}, ${profile.city}, ${profile.province} (${profile.postalCode})',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: items
            .map(
              (pair) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        pair.$1,
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        pair.$2,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
    required this.label,
    required this.imageUrl,
  });

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => Container(
                  color: colors.surfaceSubtle,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    imageUrl,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewApplicationDialog extends ConsumerStatefulWidget {
  const _ReviewApplicationDialog({required this.item});

  final VacancyApplicationItem item;

  @override
  ConsumerState<_ReviewApplicationDialog> createState() =>
      _ReviewApplicationDialogState();
}

class _ReviewApplicationDialogState
    extends ConsumerState<_ReviewApplicationDialog> {
  bool _isApproved = true;
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
    final repo = ref.read(recruitmentRepositoryProvider);
    final res = await repo.submitApplicantReview(
      userAdvertId: widget.item.userAdvertId,
      isApproved: _isApproved,
      rejectionReason: _reasonController.text,
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
    return AlertDialog(
      title: Text('Review lamaran: ${widget.item.fullName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorText != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.dangerMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Terima (Approved)'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Tolak'),
                  icon: Icon(Icons.cancel_outlined),
                ),
              ],
              selected: <bool>{_isApproved},
              onSelectionChanged: (selection) {
                setState(() => _isApproved = selection.first);
              },
            ),
            if (!_isApproved) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan berkas',
                  hintText: 'Wajib diisi apabila lamaran ditolak...',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelButton),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.saveButton),
        ),
      ],
    );
  }
}

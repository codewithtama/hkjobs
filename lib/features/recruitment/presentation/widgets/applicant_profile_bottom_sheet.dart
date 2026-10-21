import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/widgets/hk_state_views.dart';
import '../../../../core/widgets/hk_whatsapp_button.dart';
import '../../data/recruitment_repository.dart';
import '../../domain/recruitment_models.dart';

class ApplicantProfileBottomSheet extends ConsumerWidget {
  const ApplicantProfileBottomSheet({
    required this.applicantId,
    required this.initialName,
    super.key,
  });

  final String applicantId;
  final String initialName;

  static void show(
    BuildContext context, {
    required String applicantId,
    required String initialName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ApplicantProfileBottomSheet(
        applicantId: applicantId,
        initialName: initialName,
      ),
    );
  }

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
          Success<ApplicantFullProfile>(:final data) =>
            DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
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
                    if (WhatsAppLauncher.isValidPhone(data.phone)) ...[
                      const SizedBox(height: 12),
                      HkWhatsAppButton(
                        phone: data.phone,
                        candidateName: data.fullName,
                        contextDescription:
                            'lamaran posisi ${data.positionName}',
                        label: 'Chat WhatsApp Pelamar',
                      ),
                    ],
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
                      child: Text(pair.$1, style: context.textStyles.bodySmall),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pair.$2,
                              style: context.textStyles.bodyMedium,
                            ),
                          ),
                          if (pair.$1 == 'No. Telepon' &&
                              WhatsAppLauncher.isValidPhone(pair.$2)) ...[
                            const SizedBox(width: 8),
                            HkWhatsAppIconButton(
                              phone: pair.$2,
                              candidateName: profile.fullName,
                              contextDescription:
                                  'lamaran posisi ${profile.positionName}',
                            ),
                          ],
                        ],
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
  const _DocumentPreviewCard({required this.label, required this.imageUrl});

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

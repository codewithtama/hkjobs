import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';

final trainingParticipantsProvider = FutureProvider.autoDispose
    .family<List<TrainingParticipantItem>, String>((ref, trainingId) async {
  final repo = ref.watch(academyRepositoryProvider);
  final res = await repo.fetchTrainingParticipants(trainingId);
  switch (res) {
    case Success<PaginatedList<TrainingParticipantItem>>(:final data):
      return data.items;
    case Failure<PaginatedList<TrainingParticipantItem>>(:final error):
      throw error;
  }
});

class TrainingParticipantsScreen extends ConsumerStatefulWidget {
  const TrainingParticipantsScreen({
    required this.trainingId,
    this.trainingCode,
    super.key,
  });

  final String trainingId;
  final String? trainingCode;

  @override
  ConsumerState<TrainingParticipantsScreen> createState() =>
      _TrainingParticipantsScreenState();
}

class _TrainingParticipantsScreenState
    extends ConsumerState<TrainingParticipantsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEvaluationDialog({
    required TrainingParticipantItem participant,
    required bool isPassed,
  }) async {
    final statusRes = await ref
        .read(academyRepositoryProvider)
        .fetchTrainingParticipantStatus(participant.id);

    if (!mounted) return;

    if (statusRes case Failure<Map<String, Object?>>(:final error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data peserta: ${error.message}'),
          backgroundColor: context.colors.danger,
        ),
      );
      return;
    }

    final data = (statusRes as Success<Map<String, Object?>>).data;
    final trainingListId =
        data['id_training_list']?.toString() ?? participant.id;
    final userId = data['id_user']?.toString() ?? '';

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID Pelamar tidak ditemukan pada server.'),
          backgroundColor: context.colors.danger,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        final title = isPassed
            ? 'Loloskan Peserta Training'
            : 'Tidak Loloskan Peserta Training';
        final actionColor = isPassed ? colors.accent : colors.danger;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: actionColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: dialogContext.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.participantName,
                  style: dialogContext.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isPassed
                        ? 'Alasan Diloloskan'
                        : 'Alasan Tidak Diloloskan (wajib)',
                    hintText: 'Tuliskan catatan evaluasi...',
                  ),
                  validator: (v) {
                    if (!isPassed && (v == null || v.trim().isEmpty)) {
                      return 'Alasan tidak lolos wajib diisi.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: actionColor),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(academyRepositoryProvider);
    final Result<void> result;
    if (isPassed) {
      result = await repo.submitTrainingPassed(
        trainingListId: trainingListId,
        userId: userId,
        reason: reasonController.text.trim(),
      );
    } else {
      result = await repo.submitTrainingFailed(
        trainingListId: trainingListId,
        userId: userId,
        reason: reasonController.text.trim(),
      );
    }

    if (!mounted) return;

    switch (result) {
      case Failure<void>(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: context.colors.danger,
          ),
        );
      case Success<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPassed
                ? 'Peserta berhasil diloloskan.'
                : 'Status peserta diperbarui menjadi tidak lolos.'),
            backgroundColor: context.colors.accent,
          ),
        );
        ref.invalidate(trainingParticipantsProvider(widget.trainingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync =
        ref.watch(trainingParticipantsProvider(widget.trainingId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trainingCode != null
            ? '${FormStrings.participantsTitle} (${widget.trainingCode})'
            : FormStrings.participantsTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama peserta...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: participantsAsync.when(
              loading: () => const HkLoadingView(
                message: FormStrings.loadingParticipants,
              ),
              error: (err, _) => HkErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  trainingParticipantsProvider(widget.trainingId),
                ),
              ),
              data: (items) {
                final filtered = items.where((e) {
                  if (_search.isEmpty) return true;
                  return e.participantName.toLowerCase().contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const HkEmptyView(
                    title: 'Tidak ada peserta training',
                    subtitle: 'Belum ada data peserta untuk jadwal ini.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.participantName,
                                        style: context.textStyles.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jadwal: ${item.date} • ${item.trainerLocation}',
                                        style: context.textStyles.bodySmall?.copyWith(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                HkStatusBadge.fromStatusText(item.status),
                              ],
                            ),
                            if (item.reason.isNotEmpty && item.reason != '-') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Catatan: ${item.reason}',
                                  style: context.textStyles.bodySmall,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.danger,
                                    side: BorderSide(color: colors.danger),
                                  ),
                                  onPressed: () => _showEvaluationDialog(
                                    participant: item,
                                    isPassed: false,
                                  ),
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  label: const Text(FormStrings.failAction),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.accent,
                                  ),
                                  onPressed: () => _showEvaluationDialog(
                                    participant: item,
                                    isPassed: true,
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text(FormStrings.passAction),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

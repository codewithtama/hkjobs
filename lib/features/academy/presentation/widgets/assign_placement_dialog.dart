import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/academy_repository.dart';
import '../../domain/academy_models.dart';

class AssignPlacementDialog extends ConsumerStatefulWidget {
  const AssignPlacementDialog({required this.candidate, super.key});

  final PlacementWaitingItem candidate;

  static Future<bool?> show(
    BuildContext context, {
    required PlacementWaitingItem candidate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AssignPlacementDialog(candidate: candidate),
    );
  }

  @override
  ConsumerState<AssignPlacementDialog> createState() =>
      _AssignPlacementDialogState();
}

class _AssignPlacementDialogState extends ConsumerState<AssignPlacementDialog> {
  String? _selectedScheduleId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final repo = ref.watch(academyRepositoryProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_ind_outlined, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tugaskan Penempatan',
              style: context.textStyles.titleMedium,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<Result<PaginatedList<PlacementScheduleItem>>>(
          future: repo.fetchPlacementSchedules(limit: 50),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final res = snapshot.data!;
            if (res case Failure<PaginatedList<PlacementScheduleItem>>(
              :final error,
            )) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Gagal memuat jadwal penempatan: ${error.message}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.danger,
                  ),
                ),
              );
            }

            final schedules =
                (res as Success<PaginatedList<PlacementScheduleItem>>)
                    .data
                    .items;

            if (schedules.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada jadwal penempatan proyek yang dibuat. Buat jadwal penempatan terlebih dahulu.',
                  style: context.textStyles.bodyMedium,
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.candidate.applicantName,
                          style: context.textStyles.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.candidate.positionName} • Kota: ${widget.candidate.city}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Skor PKL: ${widget.candidate.pklScore} • Lolos: ${widget.candidate.passedDate}',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Jadwal Penempatan Proyek:',
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedScheduleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Pilih proyek & tanggal penempatan...',
                    ),
                    items: schedules.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(
                          '${s.code} • ${s.projectName} (Sisa Kuota: ${s.quota})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _selectedScheduleId = v;
                      _errorMessage = null;
                    }),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting || _selectedScheduleId == null
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                    _errorMessage = null;
                  });

                  final navigator = Navigator.of(context);
                  final result = await repo.assignCandidateToPlacement(
                    waitingListPlacementId: widget.candidate.id,
                    placementScheduleId: _selectedScheduleId!,
                  );

                  if (!mounted) return;

                  switch (result) {
                    case Success<void>():
                      navigator.pop(true);
                    case Failure<void>(:final error):
                      setState(() {
                        _isSubmitting = false;
                        _errorMessage = error.message;
                      });
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tugaskan'),
        ),
      ],
    );
  }
}

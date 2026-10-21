import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/recruitment_repository.dart';
import '../../domain/recruitment_models.dart';

class ReviewApplicationDialog extends ConsumerStatefulWidget {
  const ReviewApplicationDialog({required this.item, super.key});

  final VacancyApplicationItem item;

  static Future<bool?> show(
    BuildContext context, {
    required VacancyApplicationItem item,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ReviewApplicationDialog(item: item),
    );
  }

  @override
  ConsumerState<ReviewApplicationDialog> createState() =>
      _ReviewApplicationDialogState();
}

class _ReviewApplicationDialogState
    extends ConsumerState<ReviewApplicationDialog> {
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
            if (_isApproved) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accentMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kandidat yang disetujui (Approved) otomatis didaftarkan ke Jadwal Interview aktif pada lowongan ini dan menerima undangan konfirmasi di aplikasi mobile HK Jobs.',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
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

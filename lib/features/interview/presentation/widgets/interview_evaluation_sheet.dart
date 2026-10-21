import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/interview_repository.dart';
import '../../domain/interview_models.dart';

class InterviewEvaluationSheet extends ConsumerStatefulWidget {
  const InterviewEvaluationSheet({required this.candidate, super.key});

  final InterviewCandidateItem candidate;

  static Future<bool?> show(
    BuildContext context, {
    required InterviewCandidateItem candidate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InterviewEvaluationSheet(candidate: candidate),
    );
  }

  @override
  ConsumerState<InterviewEvaluationSheet> createState() =>
      _InterviewEvaluationSheetState();
}

class _InterviewEvaluationSheetState
    extends ConsumerState<InterviewEvaluationSheet> {
  InterviewEvaluationRubric _rubric = const InterviewEvaluationRubric();
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
    final repo = ref.read(interviewRepositoryProvider);
    final res = await repo.submitEvaluation(
      userAdvertId: widget.candidate.userAdvertId,
      rubric: _rubric,
      failureReason: _reasonController.text,
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
    final passed = _rubric.isPassed;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.96,
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
            Text(
              AppStrings.evaluateCandidateTitle,
              style: context.textStyles.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.candidate.fullName} (${widget.candidate.interviewCode})',
              style: context.monoStyle.copyWith(color: colors.accent),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: passed ? colors.successMuted : colors.dangerMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passed
                              ? 'Status: LOLOS (Passed)'
                              : 'Status: GAGAL (Failed)',
                          style: context.textStyles.titleMedium?.copyWith(
                            color: passed ? colors.success : colors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.passingThresholdNote,
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_rubric.totalScore}',
                    style: context.monoStyle.copyWith(
                      fontSize: 28,
                      color: passed ? colors.success : colors.danger,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _VerificationSwitchRow(
              label: 'Verifikasi data diri (+10 / -25)',
              value: _rubric.dataDiriSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(dataDiriSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi fisik (+10 / -25)',
              value: _rubric.fisikSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(fisikSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Pengalaman kerja ada (+5 / 0)',
              value: _rubric.pengalamanAda,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(pengalamanAda: v)),
            ),
            _VerificationSwitchRow(
              label: 'Pengalaman sesuai posisi (+5 / 0)',
              value: _rubric.pengalamanSesuai,
              onChanged: (v) => setState(
                () => _rubric = _rubric.copyWith(pengalamanSesuai: v),
              ),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi ijazah asli (+5 / 0)',
              value: _rubric.ijazahSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(ijazahSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi SKCK (+5 / 0)',
              value: _rubric.skckSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(skckSesuai: v)),
            ),
            _VerificationSwitchRow(
              label: 'Verifikasi SIO (+5 / 0)',
              value: _rubric.sioSesuai,
              onChanged: (v) =>
                  setState(() => _rubric = _rubric.copyWith(sioSesuai: v)),
            ),
            const Divider(height: 24),
            _RateSelectorRow(
              title: 'Skor penampilan / Grooming',
              selectedValue: _rubric.groomingRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(groomingRate: v)),
            ),
            const SizedBox(height: 12),
            _RateSelectorRow(
              title: 'Skor intelejensi',
              selectedValue: _rubric.intelejenRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(intelejenRate: v)),
            ),
            const SizedBox(height: 12),
            _RateSelectorRow(
              title: 'Skor komunikasi',
              selectedValue: _rubric.komunikasiRate,
              onSelected: (v) =>
                  setState(() => _rubric = _rubric.copyWith(komunikasiRate: v)),
            ),
            if (!passed) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan gagal interview (Wajib jika skor ≤ 64)',
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.submitEvaluationButton),
            ),
          ],
        );
      },
    );
  }
}

class _VerificationSwitchRow extends StatelessWidget {
  const _VerificationSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.textStyles.bodyMedium),
      subtitle: Text(
        value ? 'Sesuai / Ada' : 'Tidak sesuai / Tidak ada',
        style: context.textStyles.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _RateSelectorRow extends StatelessWidget {
  const _RateSelectorRow({
    required this.title,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final int selectedValue;
  final ValueChanged<int> onSelected;

  static const List<int> _options = <int>[2, 4, 6, 8, 10];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: _options
              .map(
                (score) => ChoiceChip(
                  label: Text('+$score'),
                  selected: selectedValue == score,
                  onSelected: (_) => onSelected(score),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

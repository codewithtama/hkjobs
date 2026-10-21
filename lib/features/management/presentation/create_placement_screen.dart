import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/form_html_parser.dart';
import '../../../core/widgets/hk_form_widgets.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/management_repository.dart';

class CreatePlacementScreen extends ConsumerStatefulWidget {
  const CreatePlacementScreen({super.key});

  @override
  ConsumerState<CreatePlacementScreen> createState() =>
      _CreatePlacementScreenState();
}

class _CreatePlacementScreenState extends ConsumerState<CreatePlacementScreen> {
  final _formKey = GlobalKey<FormState>();

  Set<String> _selectedProject = <String>{};
  final TextEditingController _lokasiProjectController =
      TextEditingController();
  Set<String> _selectedPosition = <String>{};
  final TextEditingController _quotaController = TextEditingController(
    text: '1',
  );
  String? _date;
  String? _timeStart = '08:00';
  String? _timeEnd = '17:00';

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _lokasiProjectController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedProject.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.placementProject),
      );
      return;
    }
    if (_selectedPosition.isEmpty) {
      setState(
        () =>
            _submitError = FormStrings.required(FormStrings.placementPosition),
      );
      return;
    }
    if (_date == null || _date!.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.placementDate),
      );
      return;
    }

    final quota = int.tryParse(_quotaController.text.trim()) ?? 0;
    if (quota < 1 || quota > 50) {
      setState(() => _submitError = 'Kuota penempatan harus antara 1 dan 50.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final draft = PlacementDraft(
      projectId: _selectedProject.first,
      lokasiProject: _lokasiProjectController.text.trim(),
      positionId: _selectedPosition.first,
      quota: quota.toString(),
      tanggal: _date!,
      timeStart: _timeStart ?? '08:00',
      timeEnd: _timeEnd ?? '17:00',
    );

    final res = await ref
        .read(managementRepositoryProvider)
        .createPlacement(draft);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (res) {
      case Success<void>():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(FormStrings.savedSuccess)));
        context.pop(true);
      case Failure<void>(:final error):
        setState(() => _submitError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectsAsync = ref.watch(
      formSelectsProvider(ApiEndpoints.placementScheduleForm),
    );
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text(FormStrings.createPlacementTitle)),
      body: selectsAsync.when(
        loading: () => const HkLoadingView(message: FormStrings.loadingForm),
        error: (err, _) => HkErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(
            formSelectsProvider(ApiEndpoints.placementScheduleForm),
          ),
        ),
        data: (selects) {
          final projectOptions = selects['projectId'] ?? const <SelectOption>[];
          final positionOptions =
              selects['positionId'] ?? const <SelectOption>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_submitError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.dangerMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Informasi Proyek & Penempatan',
                  style: context.textStyles.titleSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                HkPickerField(
                  label: FormStrings.placementProject,
                  options: projectOptions,
                  selected: _selectedProject,
                  onChanged: (v) {
                    setState(() {
                      _selectedProject = v;
                      if (v.isNotEmpty &&
                          _lokasiProjectController.text.isEmpty) {
                        final matched = projectOptions.where(
                          (p) => p.value == v.first,
                        );
                        if (matched.isNotEmpty) {
                          _lokasiProjectController.text = matched.first.label;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lokasiProjectController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: FormStrings.placementLocation,
                    hintText:
                        'Tuliskan nama area, gedung, atau alamat proyek...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return FormStrings.required(
                        FormStrings.placementLocation,
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.placementPosition,
                  options: positionOptions,
                  selected: _selectedPosition,
                  onChanged: (v) => setState(() => _selectedPosition = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quotaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: FormStrings.placementQuota,
                    hintText: 'Contoh: 1',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return FormStrings.required(FormStrings.placementQuota);
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1 || n > 50) {
                      return 'Kuota minimal 1 dan maksimal 50.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Jadwal & Waktu',
                  style: context.textStyles.titleSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                HkDateField(
                  label: FormStrings.placementDate,
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HkTimeField(
                        label: FormStrings.placementTimeStart,
                        value: _timeStart,
                        onChanged: (t) => setState(() => _timeStart = t),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HkTimeField(
                        label: FormStrings.placementTimeEnd,
                        value: _timeEnd,
                        onChanged: (t) => setState(() => _timeEnd = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(FormStrings.createPlacementAction),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

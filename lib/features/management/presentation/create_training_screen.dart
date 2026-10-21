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

class CreateTrainingScreen extends ConsumerStatefulWidget {
  const CreateTrainingScreen({super.key});

  @override
  ConsumerState<CreateTrainingScreen> createState() =>
      _CreateTrainingScreenState();
}

class _CreateTrainingScreenState extends ConsumerState<CreateTrainingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _customAddressController = TextEditingController();

  Set<String> _selectedBranch = <String>{};
  Set<String> _selectedLocation = <String>{};
  String _areaCabang = '';
  String _lokasiCabang = '';
  bool _useCustomAddress = false;

  String? _startDate;
  String? _endDate;
  String? _timeStart = '08:00';
  String? _timeEnd = '17:00';

  Set<String> _selectedRank = <String>{};
  Set<String> _selectedPosition = <String>{};

  final List<QuotaRowDraft> _quotas = [QuotaRowDraft()];

  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _codeController.dispose();
    _customAddressController.dispose();
    super.dispose();
  }

  Future<void> _onLocationSelected(Set<String> selection) async {
    setState(() {
      _selectedLocation = selection;
      _areaCabang = '';
      _lokasiCabang = '';
    });
    if (selection.isEmpty) return;

    setState(() => _isLoadingLocation = true);

    final res = await ref
        .read(managementRepositoryProvider)
        .loadLocationInfo(
          endpoint: ApiEndpoints.trainingLocationDetail,
          locationId: selection.first,
        );

    if (!mounted) return;

    setState(() => _isLoadingLocation = false);

    switch (res) {
      case Success<LocationInfo>(:final data):
        setState(() {
          _areaCabang = data.area;
          _lokasiCabang = data.address;
        });
      case Failure<LocationInfo>(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat alamat training: ${error.message}'),
            backgroundColor: context.colors.danger,
          ),
        );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedBranch.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingBranch),
      );
      return;
    }
    if (_selectedLocation.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingLocation),
      );
      return;
    }
    if (_startDate == null || _startDate!.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingStart),
      );
      return;
    }
    if (_endDate == null || _endDate!.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingEnd),
      );
      return;
    }
    if (_selectedRank.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingRank),
      );
      return;
    }
    if (_selectedPosition.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.trainingPosition),
      );
      return;
    }

    final validQuotas = FormValidators.collectQuotas(_quotas);
    if (validQuotas.isEmpty) {
      setState(() => _submitError = FormStrings.quotaRowsRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final draft = TrainingDraft(
      code: _codeController.text.trim(),
      branchId: _selectedBranch.first,
      locationId: _selectedLocation.first,
      area: _areaCabang,
      address: _lokasiCabang,
      customAddress: _useCustomAddress
          ? _customAddressController.text.trim()
          : null,
      startDate: _startDate!,
      endDate: _endDate!,
      timeStart: _timeStart ?? '08:00',
      timeEnd: _timeEnd ?? '17:00',
      rank: _selectedRank.first,
      positionId: _selectedPosition.first,
      quotas: validQuotas,
    );

    final res = await ref
        .read(managementRepositoryProvider)
        .createTraining(draft);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (res) {
      case Failure<void>(:final error):
        setState(() => _submitError = error.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: context.colors.danger,
          ),
        );
      case Success<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(FormStrings.savedSuccess),
            backgroundColor: context.colors.accent,
          ),
        );
        context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectsAsync = ref.watch(
      formSelectsProvider(ApiEndpoints.trainingCreate),
    );
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text(FormStrings.createTrainingTitle)),
      body: selectsAsync.when(
        loading: () => const HkLoadingView(message: FormStrings.loadingForm),
        error: (err, _) => HkErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(formSelectsProvider(ApiEndpoints.trainingCreate)),
        ),
        data: (selects) {
          final branchOptions = selects['advertId'] ?? const <SelectOption>[];
          final locationOptions =
              selects['lokasiDetailCabang'] ?? const <SelectOption>[];
          final rankOptions = selects['rankCourse'] ?? const <SelectOption>[];
          final positionOptions = selects['jobId'] ?? const <SelectOption>[];
          final trainerOptions = selects['admin[]'] ?? const <SelectOption>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_submitError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.danger.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.danger),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: FormStrings.trainingCode,
                    hintText: 'Misal: TR-2026-JKT-01',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.trainingCode,
                  ),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.trainingBranch,
                  options: branchOptions,
                  selected: _selectedBranch,
                  onChanged: (v) => setState(() => _selectedBranch = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.trainingLocation,
                  options: locationOptions,
                  selected: _selectedLocation,
                  isLoading: _isLoadingLocation,
                  onChanged: _onLocationSelected,
                ),
                if (_areaCabang.isNotEmpty || _lokasiCabang.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${FormStrings.locationArea}: $_areaCabang',
                          style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lokasiCabang,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text(FormStrings.trainingCustomAddress),
                  subtitle: const Text(
                    'Centang jika pelatihan diadakan di lokasi kustom',
                  ),
                  value: _useCustomAddress,
                  onChanged: (v) =>
                      setState(() => _useCustomAddress = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_useCustomAddress) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customAddressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: FormStrings.trainingCustomAddressField,
                      hintText:
                          'Tuliskan nama gedung dan detail alamat lokasi training...',
                    ),
                    validator: (v) => _useCustomAddress
                        ? FormValidators.requiredText(
                            v ?? '',
                            FormStrings.trainingCustomAddressField,
                          )
                        : null,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HkDateField(
                        label: FormStrings.trainingStart,
                        value: _startDate,
                        onChanged: (v) => setState(() => _startDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HkDateField(
                        label: FormStrings.trainingEnd,
                        value: _endDate,
                        onChanged: (v) => setState(() => _endDate = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HkTimeField(
                        label: FormStrings.timeStart,
                        value: _timeStart,
                        onChanged: (v) => setState(() => _timeStart = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HkTimeField(
                        label: FormStrings.timeEnd,
                        value: _timeEnd,
                        onChanged: (v) => setState(() => _timeEnd = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.trainingRank,
                  options: rankOptions,
                  selected: _selectedRank,
                  onChanged: (v) => setState(() => _selectedRank = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.trainingPosition,
                  options: positionOptions,
                  selected: _selectedPosition,
                  onChanged: (v) => setState(() => _selectedPosition = v),
                ),
                const SizedBox(height: 20),
                HkQuotaRows(
                  title: FormStrings.trainerRows,
                  personLabel: FormStrings.trainerLabel,
                  personOptions: trainerOptions,
                  rows: _quotas,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting ? FormStrings.saving : FormStrings.save,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

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

class CreateInterviewScreen extends ConsumerStatefulWidget {
  const CreateInterviewScreen({super.key});

  @override
  ConsumerState<CreateInterviewScreen> createState() =>
      _CreateInterviewScreenState();
}

class _CreateInterviewScreenState extends ConsumerState<CreateInterviewScreen> {
  final _formKey = GlobalKey<FormState>();

  Set<String> _selectedVacancy = <String>{};
  Set<String> _selectedLocation = <String>{};
  String _areaCabang = '';
  String _lokasiCabang = '';
  String? _date;
  String? _timeStart = '08:00';
  String? _timeEnd = '17:00';

  final List<QuotaRowDraft> _quotas = [QuotaRowDraft()];

  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _submitError;

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
          endpoint: ApiEndpoints.interviewLocationDetail,
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
            content: Text('Gagal memuat alamat cabang: ${error.message}'),
            backgroundColor: context.colors.danger,
          ),
        );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedVacancy.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.interviewVacancy),
      );
      return;
    }
    if (_selectedLocation.isEmpty) {
      setState(
        () =>
            _submitError = FormStrings.required(FormStrings.interviewLocation),
      );
      return;
    }
    if (_date == null || _date!.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.interviewDate),
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

    final draft = InterviewDraft(
      vacancyId: _selectedVacancy.first,
      locationId: _selectedLocation.first,
      area: _areaCabang,
      address: _lokasiCabang,
      date: _date!,
      timeStart: _timeStart ?? '08:00',
      timeEnd: _timeEnd ?? '17:00',
      quotas: validQuotas,
    );

    final res = await ref
        .read(managementRepositoryProvider)
        .createInterview(draft);

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
      formSelectsProvider(ApiEndpoints.interviewCreate),
    );
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text(FormStrings.createInterviewTitle)),
      body: selectsAsync.when(
        loading: () => const HkLoadingView(message: FormStrings.loadingForm),
        error: (err, _) => HkErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(formSelectsProvider(ApiEndpoints.interviewCreate)),
        ),
        data: (selects) {
          final vacancyOptions = selects['advertId'] ?? const <SelectOption>[];
          final locationOptions =
              selects['lokasiDetailCabang'] ?? const <SelectOption>[];
          final interviewerOptions =
              selects['admin[]'] ?? const <SelectOption>[];

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
                HkPickerField(
                  label: FormStrings.interviewVacancy,
                  options: vacancyOptions,
                  selected: _selectedVacancy,
                  onChanged: (v) => setState(() => _selectedVacancy = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.interviewLocation,
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
                const SizedBox(height: 14),
                HkDateField(
                  label: FormStrings.interviewDate,
                  value: _date,
                  onChanged: (v) => setState(() => _date = v),
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
                const SizedBox(height: 20),
                HkQuotaRows(
                  title: FormStrings.interviewerRows,
                  personLabel: FormStrings.interviewerLabel,
                  personOptions: interviewerOptions,
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

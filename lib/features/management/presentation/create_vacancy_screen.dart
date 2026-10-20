import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/form_html_parser.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/widgets/hk_form_widgets.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/management_repository.dart';

class CreateVacancyScreen extends ConsumerStatefulWidget {
  const CreateVacancyScreen({super.key});

  @override
  ConsumerState<CreateVacancyScreen> createState() =>
      _CreateVacancyScreenState();
}

class _CreateVacancyScreenState extends ConsumerState<CreateVacancyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  Set<String> _selectedBranch = <String>{};
  Set<String> _selectedSubBranch = <String>{};
  List<SelectOption> _subBranchOptions = const [];
  bool _isLoadingSubBranches = false;

  Set<String> _selectedPosition = <String>{};
  Set<String> _selectedCities = <String>{};
  Set<String> _selectedExperience = <String>{};
  String? _startDate;
  String? _endDate;

  PickedImage? _iconImage;
  PickedImage? _bannerImage;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onBranchSelected(Set<String> selection) async {
    setState(() {
      _selectedBranch = selection;
      _selectedSubBranch = <String>{};
      _subBranchOptions = const [];
    });
    if (selection.isEmpty) return;

    setState(() => _isLoadingSubBranches = true);

    final res = await ref.read(managementRepositoryProvider).loadLocations(
          endpoint: ApiEndpoints.vacancyBranchLocations,
          parentId: selection.first,
          usePost: true,
        );

    if (!mounted) return;

    setState(() => _isLoadingSubBranches = false);

    switch (res) {
      case Success<List<SelectOption>>(:final data):
        setState(() => _subBranchOptions = data);
      case Failure<List<SelectOption>>(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat cabang pembantu: ${error.message}'),
            backgroundColor: context.colors.danger,
          ),
        );
    }
  }

  Future<void> _onSubBranchSelected(Set<String> selection) async {
    setState(() => _selectedSubBranch = selection);
    if (selection.isEmpty) return;

    final res = await ref
        .read(managementRepositoryProvider)
        .loadVacancyCodePrefix(selection.first);

    if (!mounted) return;

    if (res case Success<String>(:final data)) {
      if (_codeController.text.isEmpty ||
          !_codeController.text.startsWith(data)) {
        setState(() {
          _codeController.text = data;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedBranch.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyBranch));
      return;
    }
    if (_selectedSubBranch.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancySubBranch));
      return;
    }
    if (_selectedPosition.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyPosition));
      return;
    }
    if (_selectedCities.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyCities));
      return;
    }
    if (_selectedExperience.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyExperience));
      return;
    }
    if (_startDate == null || _startDate!.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyStart));
      return;
    }
    if (_endDate == null || _endDate!.isEmpty) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyEnd));
      return;
    }
    if (_iconImage == null) {
      setState(() => _submitError = FormStrings.required(FormStrings.vacancyIcon));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final draft = VacancyDraft(
      branchId: _selectedBranch.first,
      subBranchId: _selectedSubBranch.first,
      code: _codeController.text.trim(),
      positionId: _selectedPosition.first,
      descriptionHtml: _descriptionController.text.trim(),
      cityIds: _selectedCities.toList(),
      experience: _selectedExperience.first,
      startDate: _startDate!,
      endDate: _endDate!,
      icon: _iconImage,
      banner: _bannerImage,
    );

    final res =
        await ref.read(managementRepositoryProvider).createVacancy(draft);

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
    final selectsAsync =
        ref.watch(formSelectsProvider(ApiEndpoints.vacancyCreate));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(FormStrings.createVacancyTitle),
      ),
      body: selectsAsync.when(
        loading: () =>
            const HkLoadingView(message: FormStrings.loadingForm),
        error: (err, _) => HkErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(formSelectsProvider(ApiEndpoints.vacancyCreate)),
        ),
        data: (selects) {
          final branchOptions = selects['branchId'] ?? const <SelectOption>[];
          final positionOptions = selects['jobId'] ?? const <SelectOption>[];
          final cityOptions =
              selects['selectProvince[]'] ?? const <SelectOption>[];
          final expOptions =
              selects['optionPengalaman'] ?? const <SelectOption>[];

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
                  label: FormStrings.vacancyBranch,
                  options: branchOptions,
                  selected: _selectedBranch,
                  onChanged: _onBranchSelected,
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.vacancySubBranch,
                  options: _subBranchOptions,
                  selected: _selectedSubBranch,
                  isLoading: _isLoadingSubBranches,
                  onChanged: _onSubBranchSelected,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: FormStrings.vacancyCode,
                    hintText: 'Contoh: HO_CS_2026',
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.vacancyCode,
                  ),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.vacancyPosition,
                  options: positionOptions,
                  selected: _selectedPosition,
                  onChanged: (v) => setState(() => _selectedPosition = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.vacancyCities,
                  options: cityOptions,
                  selected: _selectedCities,
                  multi: true,
                  onChanged: (v) => setState(() => _selectedCities = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.vacancyExperience,
                  options: expOptions,
                  selected: _selectedExperience,
                  onChanged: (v) => setState(() => _selectedExperience = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HkDateField(
                        label: FormStrings.vacancyStart,
                        value: _startDate,
                        onChanged: (v) => setState(() => _startDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HkDateField(
                        label: FormStrings.vacancyEnd,
                        value: _endDate,
                        onChanged: (v) => setState(() => _endDate = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: FormStrings.vacancyDescription,
                    hintText: 'Deskripsi kualifikasi, tugas pekerjaan, dan persyaratan...',
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.vacancyDescription,
                  ),
                ),
                const SizedBox(height: 16),
                HkImageField(
                  label: FormStrings.vacancyIcon,
                  image: _iconImage,
                  onChanged: (img) => setState(() => _iconImage = img),
                ),
                const SizedBox(height: 16),
                HkImageField(
                  label: FormStrings.vacancyBanner,
                  image: _bannerImage,
                  onChanged: (img) => setState(() => _bannerImage = img),
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
                  label: Text(_isSubmitting
                      ? FormStrings.saving
                      : FormStrings.save),
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

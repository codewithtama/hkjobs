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

class CreateAdminScreen extends ConsumerStatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  ConsumerState<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends ConsumerState<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _positionController = TextEditingController();

  Set<String> _selectedRole = <String>{};
  Set<String> _selectedBranch = <String>{};
  Set<String> _selectedStatus = <String>{'1'};
  PickedImage? _photo;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedRole.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.adminRole),
      );
      return;
    }
    if (_selectedBranch.isEmpty) {
      setState(
        () => _submitError = FormStrings.required(FormStrings.adminBranch),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _submitError = FormStrings.adminPasswordMismatch);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final draft = AdminDraft(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      role: _selectedRole.first,
      branchId: _selectedBranch.first,
      position: _positionController.text.trim(),
      isActive: _selectedStatus.firstOrNull == '1',
      photo: _photo,
    );

    final res = await ref.read(managementRepositoryProvider).createAdmin(draft);

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
      formSelectsProvider(ApiEndpoints.adminCreate),
    );
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text(FormStrings.createAdminTitle)),
      body: selectsAsync.when(
        loading: () => const HkLoadingView(message: FormStrings.loadingForm),
        error: (err, _) => HkErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(formSelectsProvider(ApiEndpoints.adminCreate)),
        ),
        data: (selects) {
          final roleOptions = selects['roleAdmin'] ?? const <SelectOption>[];
          final branchOptions = selects['cabangid'] ?? const <SelectOption>[];

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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminName,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminName,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminEmail,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminEmail,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminPhone,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminPhone,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminPassword,
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminPassword,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminPasswordConfirm,
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminPasswordConfirm,
                  ),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.adminRole,
                  options: roleOptions,
                  selected: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.adminBranch,
                  options: branchOptions,
                  selected: _selectedBranch,
                  onChanged: (v) => setState(() => _selectedBranch = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: FormStrings.adminPosition,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => FormValidators.requiredText(
                    v ?? '',
                    FormStrings.adminPosition,
                  ),
                ),
                const SizedBox(height: 14),
                HkPickerField(
                  label: FormStrings.adminStatus,
                  options: const [
                    SelectOption(value: '1', label: 'Aktif'),
                    SelectOption(value: '0', label: 'Non-aktif'),
                  ],
                  selected: _selectedStatus,
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(height: 16),
                HkImageField(
                  label: FormStrings.adminPhoto,
                  image: _photo,
                  onChanged: (img) => setState(() => _photo = img),
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

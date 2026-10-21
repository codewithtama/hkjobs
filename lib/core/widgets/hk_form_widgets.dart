import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../constants/form_strings.dart';
import '../theme/app_theme.dart';
import '../utils/form_html_parser.dart';
import '../utils/picked_image.dart';

Future<Set<String>?> showHkPicker({
  required BuildContext context,
  required String title,
  required List<SelectOption> options,
  required Set<String> selected,
  required bool multi,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet(
      title: title,
      options: options,
      initial: selected,
      multi: multi,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.multi,
  });

  final String title;
  final List<SelectOption> options;
  final Set<String> initial;
  final bool multi;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final TextEditingController _search = TextEditingController();
  late final Set<String> _selection = <String>{...widget.initial};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: context.textStyles.titleLarge,
                      ),
                    ),
                    if (widget.multi)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(_selection),
                        child: const Text(FormStrings.pickerDone),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: FormStrings.pickerSearch,
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          FormStrings.pickerEmpty,
                          style: context.textStyles.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final option = filtered[i];
                          final isSelected = _selection.contains(option.value);
                          if (widget.multi) {
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(option.label),
                              onChanged: (v) => setState(() {
                                if (v ?? false) {
                                  _selection.add(option.value);
                                } else {
                                  _selection.remove(option.value);
                                }
                              }),
                            );
                          }
                          return ListTile(
                            minTileHeight: 52,
                            title: Text(option.label),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: context.colors.accent,
                                  )
                                : null,
                            onTap: () => Navigator.of(
                              context,
                            ).pop(<String>{option.value}),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HkPickerField extends StatelessWidget {
  const HkPickerField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multi = false,
    this.enabled = true,
    this.errorText,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final List<SelectOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool multi;
  final bool enabled;
  final bool isLoading;
  final String? errorText;

  String get _display {
    if (selected.isEmpty) {
      return multi
          ? FormStrings.selectPlaceholderMulti
          : FormStrings.selectPlaceholder;
    }
    final labels = options
        .where((o) => selected.contains(o.value))
        .map((o) => o.label)
        .toList();
    return labels.isEmpty ? '${selected.length}' : labels.join(', ');
  }

  Future<void> _open(BuildContext context) async {
    final result = await showHkPicker(
      context: context,
      title: label,
      options: options,
      selected: selected,
      multi: multi,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = enabled && !isLoading;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: active ? () => _open(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            enabled: active,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.arrow_drop_down_rounded),
          ),
          child: Text(
            _display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium?.copyWith(
              color: selected.isEmpty ? colors.textMuted : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class HkDateField extends StatelessWidget {
  const HkDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final DateTime? firstDate;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value == null ? now : (DateTime.tryParse(value!) ?? now);
    final start = firstDate ?? DateTime(now.year - 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(start) ? start : initial,
      firstDate: start,
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: FormStrings.pickDate,
    );
    if (picked != null) onChanged(DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
        ),
        child: Text(
          value ?? FormStrings.pickDate,
          style: context.textStyles.bodyMedium?.copyWith(
            color: value == null ? colors.textMuted : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class HkTimeField extends StatelessWidget {
  const HkTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: FormStrings.pickTime,
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onChanged('$hh:$mm');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.schedule_rounded, size: 20),
        ),
        child: Text(
          value ?? FormStrings.pickTime,
          style: context.textStyles.bodyMedium?.copyWith(
            color: value == null ? colors.textMuted : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class HkImageField extends StatefulWidget {
  const HkImageField({
    required this.label,
    required this.image,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String label;
  final PickedImage? image;
  final ValueChanged<PickedImage?> onChanged;
  final String? errorText;

  static const int maxBytes = 2048000;

  @override
  State<HkImageField> createState() => _HkImageFieldState();
}

class _HkImageFieldState extends State<HkImageField> {
  String? _localError;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > HkImageField.maxBytes) {
        setState(() => _localError = FormStrings.imageTooLarge);
        return;
      }
      setState(() => _localError = null);
      widget.onChanged(PickedImage(bytes: bytes, filename: file.name));
    } on Object {
      if (!mounted) return;
      setState(() => _localError = FormStrings.imageReadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = widget.image;
    final error = _localError ?? widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.textStyles.titleSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error == null ? colors.border : colors.danger,
            ),
          ),
          child: Row(
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    image.bytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    cacheWidth: 112,
                  ),
                )
              else
                Icon(Icons.image_outlined, size: 36, color: colors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  image?.filename ?? FormStrings.imageNotSelected,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
              ),
              if (image != null)
                IconButton(
                  tooltip: FormStrings.removeRow,
                  onPressed: () => widget.onChanged(null),
                  icon: const Icon(Icons.close_rounded),
                ),
              OutlinedButton(
                onPressed: _pick,
                child: const Text(FormStrings.pickImage),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.danger,
              ),
            ),
          ),
      ],
    );
  }
}

@immutable
class QuotaEntry {
  const QuotaEntry({required this.quota, required this.personId});

  final String quota;
  final String personId;
}

class QuotaRowDraft {
  QuotaRowDraft({this.quota = '', this.personId});

  String quota;
  String? personId;
}

class HkQuotaRows extends StatelessWidget {
  const HkQuotaRows({
    required this.title,
    required this.personLabel,
    required this.personOptions,
    required this.rows,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String personLabel;
  final List<SelectOption> personOptions;
  final List<QuotaRowDraft> rows;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    key: ObjectKey(rows[i]),
                    initialValue: rows[i].quota,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: FormStrings.quota,
                    ),
                    onChanged: (v) {
                      rows[i].quota = v.trim();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HkPickerField(
                    label: personLabel,
                    options: personOptions,
                    selected: rows[i].personId == null
                        ? const <String>{}
                        : <String>{rows[i].personId!},
                    onChanged: (s) {
                      rows[i].personId = s.isEmpty ? null : s.first;
                      onChanged();
                    },
                  ),
                ),
                if (rows.length > 1)
                  IconButton(
                    tooltip: FormStrings.removeRow,
                    onPressed: () {
                      rows.removeAt(i);
                      onChanged();
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              rows.add(QuotaRowDraft());
              onChanged();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(FormStrings.addRow),
          ),
        ),
      ],
    );
  }
}

/// Utilitas validasi sederhana yang dipakai semua form.
abstract final class FormValidators {
  static String? requiredText(String value, String label) =>
      value.trim().isEmpty ? FormStrings.required(label) : null;

  static String? requiredSelection(Set<String> value, String label) =>
      value.isEmpty ? FormStrings.required(label) : null;

  static String? requiredValue(String? value, String label) =>
      (value == null || value.isEmpty) ? FormStrings.required(label) : null;

  static List<QuotaEntry> collectQuotas(List<QuotaRowDraft> rows) {
    final entries = <QuotaEntry>[];
    for (final row in rows) {
      final person = row.personId;
      final quota = int.tryParse(row.quota);
      if (person != null && quota != null && quota > 0) {
        entries.add(QuotaEntry(quota: quota.toString(), personId: person));
      }
    }
    return entries;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

@immutable
class HkFilterData {
  const HkFilterData({
    this.branchId,
    this.startDate,
    this.endDate,
    this.experienceFilter,
    this.vacancyCode,
    this.interviewCode,
    this.city,
    this.gender,
  });

  final String? branchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? experienceFilter;
  final String? vacancyCode;
  final String? interviewCode;
  final String? city;
  final String? gender;

  int get activeCount {
    var count = 0;
    if (branchId != null && branchId!.isNotEmpty && branchId != 'All') count++;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (experienceFilter != null &&
        experienceFilter!.isNotEmpty &&
        experienceFilter != 'Semua') {
      count++;
    }
    if (vacancyCode != null && vacancyCode!.isNotEmpty) count++;
    if (interviewCode != null && interviewCode!.isNotEmpty) count++;
    if (city != null && city!.isNotEmpty) count++;
    if (gender != null && gender!.isNotEmpty) count++;
    return count;
  }

  String? get startDateFormatted =>
      startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null;

  String? get endDateFormatted =>
      endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null;

  HkFilterData copyWith({
    String? Function()? branchId,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    String? Function()? experienceFilter,
    String? Function()? vacancyCode,
    String? Function()? interviewCode,
    String? Function()? city,
    String? Function()? gender,
  }) {
    return HkFilterData(
      branchId: branchId != null ? branchId() : this.branchId,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      experienceFilter: experienceFilter != null
          ? experienceFilter()
          : this.experienceFilter,
      vacancyCode: vacancyCode != null ? vacancyCode() : this.vacancyCode,
      interviewCode: interviewCode != null
          ? interviewCode()
          : this.interviewCode,
      city: city != null ? city() : this.city,
      gender: gender != null ? gender() : this.gender,
    );
  }

  static const empty = HkFilterData();
}

Future<HkFilterData?> showHkFilterBottomSheet({
  required BuildContext context,
  required HkFilterData initial,
  bool showBranch = true,
  bool showDateRange = true,
  bool showExperience = false,
  List<String> availableVacancies = const [],
  List<String> availableInterviews = const [],
  List<String> availableCities = const [],
  List<String> availableGenders = const [],
}) {
  return showModalBottomSheet<HkFilterData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _HkFilterSheet(
      initial: initial,
      showBranch: showBranch,
      showDateRange: showDateRange,
      showExperience: showExperience,
      availableVacancies: availableVacancies,
      availableInterviews: availableInterviews,
      availableCities: availableCities,
      availableGenders: availableGenders,
    ),
  );
}

class _HkFilterSheet extends StatefulWidget {
  const _HkFilterSheet({
    required this.initial,
    this.showBranch = true,
    this.showDateRange = true,
    this.showExperience = false,
    this.availableVacancies = const [],
    this.availableInterviews = const [],
    this.availableCities = const [],
    this.availableGenders = const [],
  });

  final HkFilterData initial;
  final bool showBranch;
  final bool showDateRange;
  final bool showExperience;
  final List<String> availableVacancies;
  final List<String> availableInterviews;
  final List<String> availableCities;
  final List<String> availableGenders;

  @override
  State<_HkFilterSheet> createState() => _HkFilterSheetState();
}

class _HkFilterSheetState extends State<_HkFilterSheet> {
  late String? _branchId = widget.initial.branchId;
  late DateTime? _startDate = widget.initial.startDate;
  late DateTime? _endDate = widget.initial.endDate;
  late String? _experienceFilter = widget.initial.experienceFilter;
  late String? _vacancyCode = widget.initial.vacancyCode;
  late String? _interviewCode = widget.initial.interviewCode;
  late String? _city = widget.initial.city;
  late String? _gender = widget.initial.gender;

  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _branchId = null;
      _startDate = null;
      _endDate = null;
      _experienceFilter = null;
      _vacancyCode = null;
      _interviewCode = null;
      _city = null;
      _gender = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      HkFilterData(
        branchId: _branchId,
        startDate: _startDate,
        endDate: _endDate,
        experienceFilter: _experienceFilter,
        vacancyCode: _vacancyCode,
        interviewCode: _interviewCode,
        city: _city,
        gender: _gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 22, color: colors.accent),
                const SizedBox(width: 8),
                Text(
                  'Filter by (Filter Data)',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const Divider(height: 24),

            if (widget.showBranch) ...[
              Text(
                'Cabang',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua Cabang'),
                    selected: _branchId == null || _branchId == 'All',
                    onSelected: (val) {
                      if (val) setState(() => _branchId = 'All');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('HK02 (JAKARTA)'),
                    selected: _branchId == '1',
                    onSelected: (val) {
                      if (val) setState(() => _branchId = '1');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (widget.showDateRange) ...[
              Text(
                'Periode Tanggal (Web: date1 s/d date2)',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        _startDate != null
                            ? _displayFormat.format(_startDate!)
                            : 'Dari Tanggal',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('s/d'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event_available_rounded, size: 16),
                      label: Text(
                        _endDate != null
                            ? _displayFormat.format(_endDate!)
                            : 'Sampai Tanggal',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    icon: const Icon(Icons.clear_rounded, size: 14),
                    label: const Text(
                      'Hapus Tanggal',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],

            if (widget.showExperience) ...[
              Text(
                'Pengalaman Kerja (Web: opsiFilter)',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected:
                        _experienceFilter == null ||
                        _experienceFilter == 'Semua',
                    onSelected: (val) {
                      if (val) setState(() => _experienceFilter = 'Semua');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Ada Pengalaman'),
                    selected: _experienceFilter == 'Ada',
                    onSelected: (val) {
                      if (val) setState(() => _experienceFilter = 'Ada');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tidak Berpengalaman'),
                    selected: _experienceFilter == 'Tidak',
                    onSelected: (val) {
                      if (val) setState(() => _experienceFilter = 'Tidak');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (widget.availableVacancies.isNotEmpty) ...[
              Text(
                'Kode Lowongan',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Semua Lowongan'),
                    selected: _vacancyCode == null || _vacancyCode!.isEmpty,
                    onSelected: (val) {
                      if (val) setState(() => _vacancyCode = null);
                    },
                  ),
                  ...widget.availableVacancies
                      .take(15)
                      .map(
                        (code) => ChoiceChip(
                          label: Text(code),
                          selected: _vacancyCode == code,
                          onSelected: (val) {
                            setState(() => _vacancyCode = val ? code : null);
                          },
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (widget.availableInterviews.isNotEmpty) ...[
              Text(
                'Sesi / Kode Interview',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Semua Sesi'),
                    selected: _interviewCode == null || _interviewCode!.isEmpty,
                    onSelected: (val) {
                      if (val) setState(() => _interviewCode = null);
                    },
                  ),
                  ...widget.availableInterviews
                      .take(15)
                      .map(
                        (code) => ChoiceChip(
                          label: Text(code),
                          selected: _interviewCode == code,
                          onSelected: (val) {
                            setState(() => _interviewCode = val ? code : null);
                          },
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (widget.availableCities.isNotEmpty) ...[
              Text(
                'Kota / Domisili Pelamar',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Semua Kota'),
                    selected: _city == null || _city!.isEmpty,
                    onSelected: (val) {
                      if (val) setState(() => _city = null);
                    },
                  ),
                  ...widget.availableCities
                      .take(10)
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: _city == c,
                          onSelected: (val) {
                            setState(() => _city = val ? c : null);
                          },
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (widget.availableGenders.isNotEmpty) ...[
              Text(
                'Jenis Kelamin',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _gender == null || _gender!.isEmpty,
                    onSelected: (val) {
                      if (val) setState(() => _gender = null);
                    },
                  ),
                  ...widget.availableGenders.map(
                    (g) => ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      onSelected: (val) {
                        setState(() => _gender = val ? g : null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Terapkan Filter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HkActiveFilterChips extends StatelessWidget {
  const HkActiveFilterChips({
    super.key,
    required this.filterData,
    required this.onFilterChanged,
  });

  final HkFilterData filterData;
  final ValueChanged<HkFilterData> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    if (filterData.activeCount == 0) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (filterData.branchId != null &&
        filterData.branchId!.isNotEmpty &&
        filterData.branchId != 'All') {
      chips.add(
        Chip(
          label: Text(
            'Cabang: ${filterData.branchId == '1' ? 'HK02' : filterData.branchId}',
          ),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(branchId: () => null)),
        ),
      );
    }

    if (filterData.startDate != null || filterData.endDate != null) {
      final s = filterData.startDateFormatted ?? '...';
      final e = filterData.endDateFormatted ?? '...';
      chips.add(
        Chip(
          avatar: const Icon(Icons.calendar_today_rounded, size: 14),
          label: Text('$s s/d $e'),
          onDeleted: () => onFilterChanged(
            filterData.copyWith(startDate: () => null, endDate: () => null),
          ),
        ),
      );
    }

    if (filterData.experienceFilter != null &&
        filterData.experienceFilter!.isNotEmpty &&
        filterData.experienceFilter != 'Semua') {
      chips.add(
        Chip(
          label: Text(
            'Pengalaman: ${filterData.experienceFilter == 'Ada' ? 'Ada' : 'Belum Ada'}',
          ),
          onDeleted: () => onFilterChanged(
            filterData.copyWith(experienceFilter: () => null),
          ),
        ),
      );
    }

    if (filterData.vacancyCode != null && filterData.vacancyCode!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.business_center_outlined, size: 14),
          label: Text(filterData.vacancyCode!),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(vacancyCode: () => null)),
        ),
      );
    }

    if (filterData.interviewCode != null &&
        filterData.interviewCode!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.event_note_rounded, size: 14),
          label: Text(filterData.interviewCode!),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(interviewCode: () => null)),
        ),
      );
    }

    if (filterData.city != null && filterData.city!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.location_on_outlined, size: 14),
          label: Text(filterData.city!),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(city: () => null)),
        ),
      );
    }

    if (filterData.gender != null && filterData.gender!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(filterData.gender!),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(gender: () => null)),
        ),
      );
    }

    // Add clear all button
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.clear_all_rounded, size: 14),
        label: const Text('Reset Filter'),
        onPressed: () => onFilterChanged(HkFilterData.empty),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: chips
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 6), child: c),
            )
            .toList(),
      ),
    );
  }
}

class HkFilterByButton extends StatelessWidget {
  const HkFilterByButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasActive = count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: hasActive ? colors.accent : colors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasActive ? colors.accent : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: hasActive ? Colors.white : colors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                hasActive ? 'Filter ($count)' : 'Filter by',
                style: context.textStyles.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasActive ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

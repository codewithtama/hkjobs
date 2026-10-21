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
    this.projectLocation,
    this.positionName,
    this.city,
    this.gender,
  });

  final String? branchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? experienceFilter;
  final String? vacancyCode;
  final String? interviewCode;
  final String? projectLocation;
  final String? positionName;
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
    if (projectLocation != null && projectLocation!.isNotEmpty) count++;
    if (positionName != null && positionName!.isNotEmpty) count++;
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
    String? Function()? projectLocation,
    String? Function()? positionName,
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
      projectLocation: projectLocation != null
          ? projectLocation()
          : this.projectLocation,
      positionName: positionName != null ? positionName() : this.positionName,
      city: city != null ? city() : this.city,
      gender: gender != null ? gender() : this.gender,
    );
  }

  static const empty = HkFilterData();
}

abstract final class HkFilterMasterData {
  static const List<String> defaultPlacements = [
    'RS MITRA MEDIKA PONTIANAK',
    'THE PARK SAWANGAN',
    'CIREBON SUPER BLOK',
    'MENARA JAMSOSTEK',
    'RSUD DOKTOR RUBINI MEMPAWAH',
    'GC PARKIR - MALL KOTA KASABLANKA',
    'ARJUNA DRIVING RANGER - BOWLING',
    'SAFFRON NOBLE APARTMENT',
    'THE PARC SOUTH CITY APARTMENT',
    'RS. KHARITAS BHAKTI',
    'THE PARK SAWANGAN LABOUR SUPPYL - TRILIO',
    'CIREBON SUPER BLOCK - TRILIO',
    'RSUD dr. RUBUNI MEMPAWAH - GARDENER',
    'KEDOYA SPORT CLUB - PADEL',
    'APARTMENT GREEN VIEW - MANAGEMENT & TEKNISI',
    'PT. PADEL AREA BAHAGIA - KEMANG',
    'OAKWOOD COZMO APARTMENT',
    'SATU 8 RESIDENCE - GARDENER',
    'GKM GREEN TOWER',
    'PLAYCE ACTIVE HUB',
    'PEDULI CEPAT INTERNATIONAL HEAD OFFICE',
    'DIGIMASTER TESTING',
  ];

  static const List<String> defaultPositions = [
    'OPERATOR - CLEANING SERVICE',
    'OPERATOR - GARDENER',
    'OPERATOR - GONDOLA',
    'ADMINISTRATION',
    'RECEPTIONIST',
    'SUPERVISOR - CLEANING SERVICE',
    'TEAM LEADER - CLEANING SERVICE',
    'CHIEF SUPERVISOR',
    'FIELD MANAGER',
    'TEKNISI',
    'PEST CONTROL',
    'OPERATOR EKSPEDISI',
    'POOL ATTENDANT',
    'SUPIR OPERASIONAL',
    'LABOUR SUPPLY',
    'BELUM ADA PENGALAMAN',
  ];

  static const List<String> defaultVacancies = [
    'HK02_CSO_OKTOBER_2026',
    'HK02_CSO_SEPTEMBER_2026',
    'HK02_CSO_AGUSTUS_2026',
    'HK02_CSO_JULI_2026',
    'HK02_CSO_JUNI_2026',
    'HK02_CSO_MEI_2026',
    'HK02_CSO_APRIL_2026',
    'HK02_CSO_MARET_2026',
    'HK02_CSO_FEBRUARI_2026',
    'HK02_CSO_JANUARI_2026',
    'HK02_CSO_JAWA_BARAT_OKTOBER_2026',
    'HK02_CSO_JAWA BARAT_AGUSTUS_2026',
    'HK02_CSO_JAWA BARAT_JULI_2026',
    'HK02_CSO_JAWA BARAT_JUNI_2026',
    'HK02_CSO_JAWA BARAT_MEI_2026',
    'HK02_CSO_KALIMANTAN_SEPTEMBER_2026',
    'HK02_CSO_KALIMANTAN_AGUSTUS_2026',
    'HK02_CSO_KALIMANTAN_JULI_2026',
    'HK02_CSO_KALIMANTAN_JUNI_2026',
    'HK02_CSO_KALIMANTAN_MEI_2026',
    'HK02_CSO_KALIMANTAN_APRIL_2026',
    'HK02_GARDENER_AGUSTUS_2026',
    'HK02_GARDENER_JUNI_2026',
    'HK02_GARDENER_JANUARI_2026',
    'HK02_GONDOLA_OKTOBER_2036',
    'HK02_GONDOLA_SEPTEMBER_2026',
    'HK02_GONDOLA_AGUSTUS_2026',
    'HK02_GONDOLA_JULI_2026',
    'HK02_GONDOLA_JUNI_2026',
    'HK02_GONDOLA_MEI_2026',
    'HK02_GONDOLA_APRIL_2026',
    'HK02_RESEPSIONIS_FEBRUARI_2026',
    'HK02_RESEPSIONIS_JANUARI_2026',
    'HK02_TRILIO_OKTOBER_2026',
    'HK02_SUPERVISOR_OKTOBER_2026',
    'HK02_SPV_AGUSTUS_2026',
    'HK02_SPV_JULI_2026',
    'HK02_SPV_JUNI_2026',
    'HK02_SUPERVISOR_JANUARI_2026',
    'HK02_TEAM_LEADER_OKTOBER_2026',
    'HK02_TL_AGUSTUS_2026',
    'HK02_TL_JULI_2026',
    'HK02_TEKNISI_MARET_2026',
    'HK02_TEKNISI_JANUARI_2026',
    'HK02_PEST CONTROL_AGUSTUS_2026',
    'HK02_ACCOUNTING&FINANCE_MARET_2026',
    'HK02_ADMIN_PCI',
    'HK02_CSB25AGUSTUS_TRILIO',
    'HK02_THEPARKSAWANGAN_TRILIO',
    'HK05_RSKLARITAS_AGUSTUS2025',
    'HK05_LEADERRSKLARITAS2025',
    'HK05_OKTOBER2025',
  ];
}

Future<HkFilterData?> showHkFilterBottomSheet({
  required BuildContext context,
  required HkFilterData initial,
  bool showBranch = true,
  bool showDateRange = true,
  bool showExperience = true,
  bool showVacancy = true,
  bool showInterview = true,
  bool showPlacement = true,
  bool showPosition = true,
  bool showCity = true,
  bool showGender = true,
  List<String> availableVacancies = const [],
  List<String> availableInterviews = const [],
  List<String> availablePlacements = const [],
  List<String> availablePositions = const [],
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
      showVacancy: showVacancy,
      showInterview: showInterview,
      showPlacement: showPlacement,
      showPosition: showPosition,
      showCity: showCity,
      showGender: showGender,
      availableVacancies: availableVacancies.isNotEmpty
          ? availableVacancies
          : HkFilterMasterData.defaultVacancies,
      availableInterviews: availableInterviews,
      availablePlacements: availablePlacements.isNotEmpty
          ? availablePlacements
          : HkFilterMasterData.defaultPlacements,
      availablePositions: availablePositions.isNotEmpty
          ? availablePositions
          : HkFilterMasterData.defaultPositions,
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
    this.showExperience = true,
    this.showVacancy = true,
    this.showInterview = true,
    this.showPlacement = true,
    this.showPosition = true,
    this.showCity = true,
    this.showGender = true,
    this.availableVacancies = const [],
    this.availableInterviews = const [],
    this.availablePlacements = const [],
    this.availablePositions = const [],
    this.availableCities = const [],
    this.availableGenders = const [],
  });

  final HkFilterData initial;
  final bool showBranch;
  final bool showDateRange;
  final bool showExperience;
  final bool showVacancy;
  final bool showInterview;
  final bool showPlacement;
  final bool showPosition;
  final bool showCity;
  final bool showGender;
  final List<String> availableVacancies;
  final List<String> availableInterviews;
  final List<String> availablePlacements;
  final List<String> availablePositions;
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
  late String? _projectLocation = widget.initial.projectLocation;
  late String? _positionName = widget.initial.positionName;
  late String? _city = widget.initial.city;
  late String? _gender = widget.initial.gender;

  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  final TextEditingController _vacancySearchCtrl = TextEditingController();
  final TextEditingController _placementSearchCtrl = TextEditingController();
  final TextEditingController _positionSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _vacancySearchCtrl.dispose();
    _placementSearchCtrl.dispose();
    _positionSearchCtrl.dispose();
    super.dispose();
  }

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
      _projectLocation = null;
      _positionName = null;
      _city = null;
      _gender = null;
      _vacancySearchCtrl.clear();
      _placementSearchCtrl.clear();
      _positionSearchCtrl.clear();
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
        projectLocation: _projectLocation,
        positionName: _positionName,
        city: _city,
        gender: _gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final filteredVacancies = _vacancySearchCtrl.text.trim().isEmpty
        ? widget.availableVacancies
        : widget.availableVacancies
            .where((v) => v.toLowerCase().contains(_vacancySearchCtrl.text.trim().toLowerCase()))
            .toList();

    final filteredPlacements = _placementSearchCtrl.text.trim().isEmpty
        ? widget.availablePlacements
        : widget.availablePlacements
            .where((p) => p.toLowerCase().contains(_placementSearchCtrl.text.trim().toLowerCase()))
            .toList();

    final filteredPositions = _positionSearchCtrl.text.trim().isEmpty
        ? widget.availablePositions
        : widget.availablePositions
            .where((p) => p.toLowerCase().contains(_positionSearchCtrl.text.trim().toLowerCase()))
            .toList();

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
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
                'Filter Data Lengkap',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. LOWONGAN KERJA
                  if (widget.showVacancy && widget.availableVacancies.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lowongan Kerja (${widget.availableVacancies.length})',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_vacancyCode != null)
                          TextButton(
                            onPressed: () => setState(() => _vacancyCode = null),
                            child: const Text('Hapus Pilihan', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _vacancySearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari lowongan...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _vacancySearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _vacancySearchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: SingleChildScrollView(
                        child: Wrap(
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
                            ...filteredVacancies.map(
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
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 2. JADWAL INTERVIEW / SESI
                  if (widget.showInterview && widget.availableInterviews.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sesi / Kode Jadwal Interview (${widget.availableInterviews.length})',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_interviewCode != null)
                          TextButton(
                            onPressed: () => setState(() => _interviewCode = null),
                            child: const Text('Hapus', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua Jadwal'),
                              selected: _interviewCode == null || _interviewCode!.isEmpty,
                              onSelected: (val) {
                                if (val) setState(() => _interviewCode = null);
                              },
                            ),
                            ...widget.availableInterviews.map(
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
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. PENEMPATAN / LOKASI PROYEK
                  if (widget.showPlacement && widget.availablePlacements.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lokasi Penempatan / Proyek (${widget.availablePlacements.length})',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_projectLocation != null)
                          TextButton(
                            onPressed: () => setState(() => _projectLocation = null),
                            child: const Text('Hapus Pilihan', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _placementSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari proyek penempatan...',
                        prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                        suffixIcon: _placementSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _placementSearchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua Penempatan'),
                              selected: _projectLocation == null || _projectLocation!.isEmpty,
                              onSelected: (val) {
                                if (val) setState(() => _projectLocation = null);
                              },
                            ),
                            ...filteredPlacements.map(
                              (proj) => ChoiceChip(
                                label: Text(proj),
                                selected: _projectLocation == proj,
                                onSelected: (val) {
                                  setState(() => _projectLocation = val ? proj : null);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 4. POSISI PEKERJAAN
                  if (widget.showPosition && widget.availablePositions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Posisi Pekerjaan (${widget.availablePositions.length})',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_positionName != null)
                          TextButton(
                            onPressed: () => setState(() => _positionName = null),
                            child: const Text('Hapus', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _positionSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari posisi...',
                        prefixIcon: const Icon(Icons.work_outline_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua Posisi'),
                              selected: _positionName == null || _positionName!.isEmpty,
                              onSelected: (val) {
                                if (val) setState(() => _positionName = null);
                              },
                            ),
                            ...filteredPositions.map(
                              (pos) => ChoiceChip(
                                label: Text(pos),
                                selected: _positionName == pos,
                                onSelected: (val) {
                                  setState(() => _positionName = val ? pos : null);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 5. CABANG
                  if (widget.showBranch) ...[
                    Text(
                      'Kantor Cabang',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                        ChoiceChip(
                          label: const Text('HK05 (PONTIANAK)'),
                          selected: _branchId == '2',
                          onSelected: (val) {
                            if (val) setState(() => _branchId = '2');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 6. PERIODE TANGGAL
                  if (widget.showDateRange) ...[
                    Text(
                      'Periode Tanggal (Web: date1 s/d date2)',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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

                  // 7. PENGALAMAN KERJA
                  if (widget.showExperience) ...[
                    Text(
                      'Pengalaman Kerja (Web: opsiFilter)',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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

                  // 8. KOTA / DOMISILI
                  if (widget.showCity && widget.availableCities.isNotEmpty) ...[
                    Text(
                      'Kota / Domisili (${widget.availableCities.length})',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                        ...widget.availableCities.map(
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

                  // 9. JENIS KELAMIN
                  if (widget.showGender) ...[
                    Text(
                      'Jenis Kelamin',
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                        ChoiceChip(
                          label: const Text('Laki-laki'),
                          selected: _gender?.toLowerCase().startsWith('l') ?? false,
                          onSelected: (val) {
                            setState(() => _gender = val ? 'Laki-laki' : null);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Perempuan'),
                          selected: _gender?.toLowerCase().startsWith('p') ?? false,
                          onSelected: (val) {
                            setState(() => _gender = val ? 'Perempuan' : null);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Terapkan Filter'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
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

    if (filterData.vacancyCode != null && filterData.vacancyCode!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.business_center_outlined, size: 14),
          label: Text('Lowongan: ${filterData.vacancyCode!}'),
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
          label: Text('Jadwal: ${filterData.interviewCode!}'),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(interviewCode: () => null)),
        ),
      );
    }

    if (filterData.projectLocation != null &&
        filterData.projectLocation!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.apartment_rounded, size: 14),
          label: Text('Penempatan: ${filterData.projectLocation!}'),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(projectLocation: () => null)),
        ),
      );
    }

    if (filterData.positionName != null &&
        filterData.positionName!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.work_outline_rounded, size: 14),
          label: Text('Posisi: ${filterData.positionName!}'),
          onDeleted: () =>
              onFilterChanged(filterData.copyWith(positionName: () => null)),
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
        label: const Text('Reset Semua'),
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

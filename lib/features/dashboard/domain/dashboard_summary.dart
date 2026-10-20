import 'package:flutter/foundation.dart';

@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.totalApprove,
    required this.totalOnProcess,
    required this.totalNotApprove,
    required this.totalInterview,
    required this.totalConfirmed,
    required this.totalCanceled,
    required this.totalPassed,
    required this.totalFailed,
    required this.totalActiveApplicants,
    required this.totalNewComer,
    required this.totalExisting,
    required this.startDate,
    required this.endDate,
  });

  final int totalApprove;
  final int totalOnProcess;
  final int totalNotApprove;
  final int totalInterview;
  final int totalConfirmed;
  final int totalCanceled;
  final int totalPassed;
  final int totalFailed;
  final int totalActiveApplicants;
  final int totalNewComer;
  final int totalExisting;
  final String startDate;
  final String endDate;

  int get totalVacancyApplications =>
      totalApprove + totalOnProcess + totalNotApprove;

  static const List<String> regionalBranches = <String>[
    'RC-HO',
    'RC-JKT2',
    'RC-JABAR',
    'RC-JATENG',
    'RC-JATIM',
    'RC-BALI',
    'RC-MEDAN',
  ];

  factory DashboardSummary.fromJson(
    Map<String, Object?> json, {
    required String startDate,
    required String endDate,
  }) {
    int readInt(String key) {
      final raw = json[key];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '0') ?? 0;
    }

    return DashboardSummary(
      totalApprove: readInt('totalApprove'),
      totalOnProcess: readInt('totalOnProcess'),
      totalNotApprove: readInt('totalNotApprove'),
      totalInterview: readInt('totalInterview'),
      totalConfirmed: readInt('totalDiterima'),
      totalCanceled: readInt('totalCancel'),
      totalPassed: readInt('totalLolos'),
      totalFailed: readInt('totalGagal'),
      totalActiveApplicants: readInt('totalApplicantAktif'),
      totalNewComer: readInt('totalNewComer'),
      totalExisting: readInt('totalExisting'),
      startDate: startDate,
      endDate: endDate,
    );
  }
}

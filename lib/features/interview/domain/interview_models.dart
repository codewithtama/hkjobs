import 'package:flutter/foundation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/html_cell_parser.dart';

enum InterviewSubTab {
  schedules('Jadwal'),
  confirmed('Konfirmasi'),
  passed('Lolos'),
  failed('Gagal'),
  canceled('Batal');

  const InterviewSubTab(this.label);
  final String label;
}

@immutable
class InterviewScheduleItem {
  const InterviewScheduleItem({
    required this.id,
    required this.code,
    required this.vacancyCode,
    required this.date,
    required this.timeRange,
    required this.maxQuota,
    required this.confirmedCount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String vacancyCode;
  final String date;
  final String timeRange;
  final String maxQuota;
  final String confirmedCount;
  final String status;
  final String createdAt;

  String get qrCodeUrl => '${ApiEndpoints.qrCodeBaseUrl}SCHEDULE-$id.png';

  factory InterviewScheduleItem.fromDataTableRow(Map<String, Object?> row) {
    final id = (row['DT_RowId'] ?? '').toString();
    return InterviewScheduleItem(
      id: id,
      code: HtmlCellParser.stripHtml(row['1']),
      vacancyCode: HtmlCellParser.stripHtml(row['2']),
      date: HtmlCellParser.stripHtml(row['5']),
      timeRange: HtmlCellParser.stripHtml(row['6']),
      maxQuota: HtmlCellParser.stripHtml(row['7']),
      confirmedCount: HtmlCellParser.stripHtml(row['8']),
      status: HtmlCellParser.stripHtml(row['9']),
      createdAt: HtmlCellParser.stripHtml(row['11']),
    );
  }
}

@immutable
class InterviewCandidateItem {
  const InterviewCandidateItem({
    required this.userAdvertId,
    required this.applicantId,
    required this.fullName,
    required this.applyDate,
    required this.phone,
    required this.city,
    required this.birthInfo,
    required this.adminName,
    required this.status,
    required this.reason,
    required this.attendanceTime,
    required this.interviewerName,
    required this.vacancyCode,
    required this.interviewCode,
  });

  final String userAdvertId;
  final String applicantId;
  final String fullName;
  final String applyDate;
  final String phone;
  final String city;
  final String birthInfo;
  final String adminName;
  final String status;
  final String reason;
  final String attendanceTime;
  final String interviewerName;
  final String vacancyCode;
  final String interviewCode;

  factory InterviewCandidateItem.fromDataTableRow(Map<String, Object?> row) {
    final rowId = (row['DT_RowId'] ?? '').toString();
    final appId =
        HtmlCellParser.extractFirstFunctionArg(row['1'], 'editShowPelamar') ??
            rowId;

    return InterviewCandidateItem(
      userAdvertId: rowId,
      applicantId: appId,
      fullName: HtmlCellParser.stripHtml(row['1']),
      applyDate: HtmlCellParser.stripHtml(row['2']),
      phone: HtmlCellParser.stripHtml(row['3']),
      city: HtmlCellParser.stripHtml(row['4']),
      birthInfo: HtmlCellParser.stripHtml(row['5']),
      adminName: HtmlCellParser.stripHtml(row['6']),
      status: HtmlCellParser.stripHtml(row['9']),
      reason: HtmlCellParser.stripHtml(row['10']),
      attendanceTime: HtmlCellParser.stripHtml(row['11']),
      interviewerName: HtmlCellParser.stripHtml(row['12']),
      vacancyCode: HtmlCellParser.stripHtml(row['14']),
      interviewCode: HtmlCellParser.stripHtml(row['15']),
    );
  }
}

/// Exact 11-parameter HKJobs Interviewer Scoring Calculator
@immutable
class InterviewEvaluationRubric {
  const InterviewEvaluationRubric({
    this.dataDiriSesuai = true,
    this.fisikSesuai = true,
    this.pengalamanAda = true,
    this.pengalamanSesuai = true,
    this.ijazahSesuai = true,
    this.skckSesuai = true,
    this.sioSesuai = true,
    this.groomingRate = 8,
    this.intelejenRate = 8,
    this.komunikasiRate = 8,
    this.kejujuranBase = 25,
  });

  final bool dataDiriSesuai;
  final bool fisikSesuai;
  final bool pengalamanAda;
  final bool pengalamanSesuai;
  final bool ijazahSesuai;
  final bool skckSesuai;
  final bool sioSesuai;
  final int groomingRate;
  final int intelejenRate;
  final int komunikasiRate;
  final int kejujuranBase;

  int get totalScore {
    final nilaiDd = dataDiriSesuai ? 10 : -25;
    final nilaiFisik = fisikSesuai ? 10 : -25;
    final nilaiPelAda = pengalamanAda ? 5 : 0;
    final nilaiPelSesuai = pengalamanSesuai ? 5 : 0;
    final nilaiIjazah = ijazahSesuai ? 5 : 0;
    final nilaiSkck = skckSesuai ? 5 : 0;
    final nilaiSio = sioSesuai ? 5 : 0;

    return kejujuranBase +
        nilaiDd +
        nilaiFisik +
        nilaiPelAda +
        nilaiPelSesuai +
        nilaiIjazah +
        nilaiSkck +
        nilaiSio +
        groomingRate +
        intelejenRate +
        komunikasiRate;
  }

  bool get isPassed => totalScore >= 65;

  String get statusPelamarValue => isPassed ? 'Passed' : 'Failed';

  InterviewEvaluationRubric copyWith({
    bool? dataDiriSesuai,
    bool? fisikSesuai,
    bool? pengalamanAda,
    bool? pengalamanSesuai,
    bool? ijazahSesuai,
    bool? skckSesuai,
    bool? sioSesuai,
    int? groomingRate,
    int? intelejenRate,
    int? komunikasiRate,
  }) {
    return InterviewEvaluationRubric(
      dataDiriSesuai: dataDiriSesuai ?? this.dataDiriSesuai,
      fisikSesuai: fisikSesuai ?? this.fisikSesuai,
      pengalamanAda: pengalamanAda ?? this.pengalamanAda,
      pengalamanSesuai: pengalamanSesuai ?? this.pengalamanSesuai,
      ijazahSesuai: ijazahSesuai ?? this.ijazahSesuai,
      skckSesuai: skckSesuai ?? this.skckSesuai,
      sioSesuai: sioSesuai ?? this.sioSesuai,
      groomingRate: groomingRate ?? this.groomingRate,
      intelejenRate: intelejenRate ?? this.intelejenRate,
      komunikasiRate: komunikasiRate ?? this.komunikasiRate,
      kejujuranBase: kejujuranBase,
    );
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/utils/html_cell_parser.dart';

enum AcademySubTab {
  placementWaiting('Waiting penempatan'),
  placementSchedules('Jadwal penempatan'),
  academyNus('Akun NUS Academy'),
  psikotes('Bank psikotes'),
  trainingOffline('Training offline'),
  fieldManagers('Akun FM');

  const AcademySubTab(this.label);
  final String label;
}

@immutable
class PlacementWaitingItem {
  const PlacementWaitingItem({
    required this.id,
    required this.applicantName,
    required this.phone,
    required this.email,
    required this.pklScore,
    required this.city,
    required this.passedDate,
    required this.positionName,
  });

  final String id;
  final String applicantName;
  final String phone;
  final String email;
  final String pklScore;
  final String city;
  final String passedDate;
  final String positionName;

  factory PlacementWaitingItem.fromDataTableRow(Map<String, Object?> row) {
    return PlacementWaitingItem(
      id: (row['DT_RowId'] ?? '').toString(),
      applicantName: HtmlCellParser.stripHtml(row['1']),
      phone: HtmlCellParser.stripHtml(row['2']),
      email: HtmlCellParser.stripHtml(row['3']),
      pklScore: HtmlCellParser.stripHtml(row['4']),
      city: HtmlCellParser.stripHtml(row['5']),
      passedDate: HtmlCellParser.stripHtml(row['6']),
      positionName: HtmlCellParser.stripHtml(row['8']),
    );
  }
}

@immutable
class PlacementScheduleItem {
  const PlacementScheduleItem({
    required this.id,
    required this.code,
    required this.projectName,
    required this.quota,
    required this.positionName,
    required this.date,
  });

  final String id;
  final String code;
  final String projectName;
  final String quota;
  final String positionName;
  final String date;

  factory PlacementScheduleItem.fromDataTableRow(Map<String, Object?> row) {
    final rawId = row['DT_RowId'];
    final idFromPath = HtmlCellParser.extractTrailingPathId(row['1']);
    final idFromFunc = HtmlCellParser.extractFirstFunctionArg(
      row['6'],
      'editPenempatanschedule',
    );
    final fallbackId = (rawId ?? idFromPath ?? idFromFunc ?? '').toString();

    final code = HtmlCellParser.stripHtml(row['1']);
    final cleanCode = code.isNotEmpty && code != '-' ? code : 'PENEMPATAN_$fallbackId';

    return PlacementScheduleItem(
      id: fallbackId,
      code: cleanCode,
      projectName: HtmlCellParser.stripHtml(row['2']),
      quota: HtmlCellParser.stripHtml(row['3']),
      positionName: HtmlCellParser.stripHtml(row['4']),
      date: HtmlCellParser.stripHtml(row['5']),
    );
  }
}

@immutable
class PlacementPersonnelItem {
  const PlacementPersonnelItem({
    required this.id,
    required this.candidateName,
    required this.positionName,
    required this.projectName,
    required this.suratTugasDownloadUrl,
    required this.suratTugasPdfUrl,
    required this.status,
    required this.reason,
  });

  final String id;
  final String candidateName;
  final String positionName;
  final String projectName;
  final String suratTugasDownloadUrl;
  final String suratTugasPdfUrl;
  final String status;
  final String reason;

  bool get isAccepted =>
      status.toLowerCase().contains('terima') ||
      status.toLowerCase().contains('accepted');

  bool get isWaitingApproval =>
      status.toLowerCase().contains('wait') ||
      status.toLowerCase().contains('menunggu');

  factory PlacementPersonnelItem.fromDataTableRow(Map<String, Object?> row) {
    final rawId = (row['DT_RowId'] ?? '').toString();
    final downloadHrefs = HtmlCellParser.extractHrefs(row['5']);
    final pdfHrefs = HtmlCellParser.extractHrefs(row['7']);

    String downloadUrl = downloadHrefs.isNotEmpty ? downloadHrefs.first : '';
    if (downloadUrl.isEmpty && rawId.isNotEmpty) {
      downloadUrl =
          'https://ops.hk-indonesia.id/hkjobs/pakelarin/suratTugas/$rawId';
    } else if (downloadUrl.startsWith('/')) {
      downloadUrl = 'https://ops.hk-indonesia.id$downloadUrl';
    }

    String pdfUrl = pdfHrefs.isNotEmpty ? pdfHrefs.first : '';
    if (pdfUrl.startsWith('/')) {
      pdfUrl = 'https://ops.hk-indonesia.id$pdfUrl';
    }

    return PlacementPersonnelItem(
      id: rawId,
      candidateName: HtmlCellParser.stripHtml(row['1']),
      positionName: HtmlCellParser.stripHtml(row['2']),
      projectName: HtmlCellParser.stripHtml(row['4']),
      suratTugasDownloadUrl: downloadUrl,
      suratTugasPdfUrl: pdfUrl,
      status: HtmlCellParser.stripHtml(row['8']),
      reason: HtmlCellParser.stripHtml(row['9']),
    );
  }
}

@immutable
class AcademyAccountItem {
  const AcademyAccountItem({
    required this.id,
    required this.fullName,
    required this.nusCode,
  });

  final String id;
  final String fullName;
  final String nusCode;

  factory AcademyAccountItem.fromDataTableRow(Map<String, Object?> row) {
    return AcademyAccountItem(
      id: (row['DT_RowId'] ?? '').toString(),
      fullName: HtmlCellParser.stripHtml(row['1']),
      nusCode: HtmlCellParser.stripHtml(row['2']),
    );
  }
}

@immutable
class PsikotesQuestionItem {
  const PsikotesQuestionItem({
    required this.id,
    required this.type,
    required this.level,
    required this.question,
    required this.choices,
    required this.answer,
    required this.author,
  });

  final String id;
  final String type;
  final String level;
  final String question;
  final List<String> choices;
  final String answer;
  final String author;

  factory PsikotesQuestionItem.fromDataTableRow(Map<String, Object?> row) {
    final rawChoices = <String>[
      HtmlCellParser.stripHtml(row['4']),
      HtmlCellParser.stripHtml(row['5']),
      HtmlCellParser.stripHtml(row['6']),
      HtmlCellParser.stripHtml(row['7']),
    ].where((c) => c.isNotEmpty && c != '-').toList();

    return PsikotesQuestionItem(
      id: (row['DT_RowId'] ?? '').toString(),
      type: HtmlCellParser.stripHtml(row['1']),
      level: HtmlCellParser.stripHtml(row['2']),
      question: HtmlCellParser.stripHtml(row['3']),
      choices: rawChoices,
      answer: HtmlCellParser.stripHtml(row['8']),
      author: HtmlCellParser.stripHtml(row['11']),
    );
  }
}

@immutable
class TrainingOfflineRecord {
  const TrainingOfflineRecord({
    required this.id,
    required this.participantName,
    required this.vacancyCode,
    required this.scheduleDate,
    required this.trainerName,
    required this.status,
    required this.reason,
    required this.score,
  });

  final String id;
  final String participantName;
  final String vacancyCode;
  final String scheduleDate;
  final String trainerName;
  final String status;
  final String reason;
  final String score;

  factory TrainingOfflineRecord.fromDataTableRow(Map<String, Object?> row) {
    return TrainingOfflineRecord(
      id: (row['DT_RowId'] ?? '').toString(),
      participantName: HtmlCellParser.stripHtml(row['1']),
      vacancyCode: HtmlCellParser.stripHtml(row['2']),
      scheduleDate: HtmlCellParser.stripHtml(row['3']),
      trainerName: HtmlCellParser.stripHtml(row['4']),
      status: HtmlCellParser.stripHtml(row['5']),
      reason: HtmlCellParser.stripHtml(row['6']),
      score: HtmlCellParser.stripHtml(row['7']),
    );
  }
}

@immutable
class TrainingScheduleSummaryItem {
  const TrainingScheduleSummaryItem({
    required this.id,
    required this.code,
    required this.scheduleDate,
    required this.positionName,
    required this.time,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String scheduleDate;
  final String positionName;
  final String time;
  final String createdAt;

  factory TrainingScheduleSummaryItem.fromDataTableRow(Map<String, Object?> row) {
    return TrainingScheduleSummaryItem(
      id: (row['DT_RowId'] ?? '').toString(),
      code: HtmlCellParser.stripHtml(row['1']),
      scheduleDate: HtmlCellParser.stripHtml(row['2']),
      positionName: HtmlCellParser.stripHtml(row['3']),
      time: HtmlCellParser.stripHtml(row['4']),
      createdAt: HtmlCellParser.stripHtml(row['9']),
    );
  }
}

@immutable
class TrainingParticipantItem {
  const TrainingParticipantItem({
    required this.id,
    required this.participantName,
    required this.date,
    required this.trainerLocation,
    required this.status,
    required this.reason,
    required this.score,
    required this.updatedAt,
  });

  final String id;
  final String participantName;
  final String date;
  final String trainerLocation;
  final String status;
  final String reason;
  final String score;
  final String updatedAt;

  factory TrainingParticipantItem.fromDataTableRow(Map<String, Object?> row) {
    return TrainingParticipantItem(
      id: (row['DT_RowId'] ?? '').toString(),
      participantName: HtmlCellParser.stripHtml(row['1']),
      date: HtmlCellParser.stripHtml(row['2']),
      trainerLocation: HtmlCellParser.stripHtml(row['3']),
      status: HtmlCellParser.stripHtml(row['4']),
      reason: HtmlCellParser.stripHtml(row['5']),
      score: HtmlCellParser.stripHtml(row['6']),
      updatedAt: HtmlCellParser.stripHtml(row['9']),
    );
  }
}

@immutable
class FieldManagerItem {
  const FieldManagerItem({
    required this.id,
    required this.name,
    required this.nuc,
    required this.email,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String nuc;
  final String email;
  final String phone;
  final String status;
  final String createdAt;

  factory FieldManagerItem.fromDataTableRow(Map<String, Object?> row) {
    return FieldManagerItem(
      id: (row['DT_RowId'] ?? '').toString(),
      name: HtmlCellParser.stripHtml(row['1']),
      nuc: HtmlCellParser.stripHtml(row['2']),
      email: HtmlCellParser.stripHtml(row['3']),
      phone: HtmlCellParser.stripHtml(row['4']),
      status: HtmlCellParser.stripHtml(row['6']),
      createdAt: HtmlCellParser.stripHtml(row['8']),
    );
  }
}

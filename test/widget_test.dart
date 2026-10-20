import 'package:flutter_test/flutter_test.dart';
import 'package:hkjobs_mobile/core/utils/html_cell_parser.dart';
import 'package:hkjobs_mobile/core/widgets/hk_form_widgets.dart';
import 'package:hkjobs_mobile/features/academy/domain/academy_models.dart';
import 'package:hkjobs_mobile/features/interview/domain/interview_models.dart';
import 'package:hkjobs_mobile/features/management/data/management_repository.dart';
import 'package:hkjobs_mobile/features/recruitment/domain/recruitment_models.dart';

void main() {
  test('skor interview default lolos (>= 65)', () {
    const rubric = InterviewEvaluationRubric();
    expect(rubric.totalScore, 25 + 10 + 10 + 5 + 5 + 5 + 5 + 5 + 8 + 8 + 8);
    expect(rubric.isPassed, isTrue);
  });

  test('data diri & fisik tidak sesuai menjatuhkan skor jadi gagal', () {
    const rubric = InterviewEvaluationRubric(
      dataDiriSesuai: false,
      fisikSesuai: false,
    );
    expect(rubric.isPassed, isFalse);
    expect(rubric.statusPelamarValue, 'Failed');
  });

  test('FormValidators.collectQuotas filters invalid and empty rows', () {
    final rows = [
      QuotaRowDraft(quota: '15', personId: '158'),
      QuotaRowDraft(quota: '0', personId: '159'),
      QuotaRowDraft(quota: 'abc', personId: '160'),
      QuotaRowDraft(quota: '20', personId: null),
      QuotaRowDraft(quota: '25', personId: '161'),
    ];
    final collected = FormValidators.collectQuotas(rows);
    expect(collected.length, 2);
    expect(collected[0].quota, '15');
    expect(collected[0].personId, '158');
    expect(collected[1].quota, '25');
    expect(collected[1].personId, '161');
  });

  test('TrainingParticipantItem parses HTML row cleanly', () {
    final row = <String, Object?>{
      'DT_RowId': '1',
      '1': 'FAIZAL ILHAM',
      '2': '2026-09-30',
      '3': 'TRAINER - HEAD OFFICE',
      '4': '<label class="badge badge-danger">Tidak lolos</label>',
      '5': 'tess',
      '6': '<p>-</p>',
      '9': '30-09-2026 10:27:35',
    };
    final item = TrainingParticipantItem.fromDataTableRow(row);
    expect(item.id, '1');
    expect(item.participantName, 'FAIZAL ILHAM');
    expect(item.date, '2026-09-30');
    expect(item.trainerLocation, 'TRAINER - HEAD OFFICE');
    expect(item.status, 'Tidak lolos');
    expect(item.reason, 'tess');
    expect(item.updatedAt, '30-09-2026 10:27:35');
  });

  test('VacancyApplicationItem parses listTable2 row correctly', () {
    final row = <String, Object?>{
      'DT_RowId': 'useradv_999',
      '1': '<a href="javascript:void(0)" onclick="editShowPelamar(777)">AHMAD FAUZI</a>',
      '2': '3201234567890001',
      '3': '1998-05-12',
      '4': 'Laki-laki',
      '5': '081234567890',
      '6': 'SMA / SMK',
      '7': 'CLEANING SERVICE',
      '8': '1 Tahun',
      '9': '170 cm',
      '10': '65 kg',
      '13': 'Belum Menikah',
      '14': 'ahmad@example.com',
      '17': 'Jakarta Selatan',
      '20': '2026-10-15 08:30:00',
      '21': '<a href="https://ops.hk-indonesia.id/assetshkjobs/ktp/ktp.jpg">KTP</a>',
      '22': '<label class="badge badge-warning">On Process</label>',
    };
    final item = VacancyApplicationItem.fromVacancyApplicantsTableRow(row);
    expect(item.userAdvertId, 'useradv_999');
    expect(item.applicantId, '777');
    expect(item.fullName, 'AHMAD FAUZI');
    expect(item.nik, '3201234567890001');
    expect(item.phone, '081234567890');
    expect(item.email, 'ahmad@example.com');
    expect(item.lastPosition, 'CLEANING SERVICE');
    expect(item.city, 'Jakarta Selatan');
    expect(item.statusText, 'On Process');
  });

  test('InterviewCandidateItem parses listTable2 participant row correctly', () {
    final row = <String, Object?>{
      'DT_RowId': 'row_55',
      '1': '<a href="javascript:void(0)" onclick="editShowPelamar(333)">BUDI SANTOSO</a>',
      '4': '2026-10-18',
      '6': '08987654321',
      '7': 'Bandung',
      '8': '1995-02-10',
      '9': 'SECURITY OFFICER',
      '13': '<label class="badge badge-success">Passed</label>',
      '15': 'Nilai memenuhi syarat',
      '16': '2026-10-19 09:00',
      '17': 'DIMAS ALFA PRATAMA',
      '19': 'INT-2026-001',
    };
    final item = InterviewCandidateItem.fromScheduleParticipantsTableRow(
      row,
      fallbackInterviewCode: 'SCH-001',
      fallbackVacancyCode: 'VAC-001',
    );
    expect(item.fullName, 'BUDI SANTOSO');
    expect(item.applicantId, '333');
    expect(item.phone, '08987654321');
    expect(item.city, 'Bandung');
    expect(item.status, 'Passed');
    expect(item.interviewerName, 'DIMAS ALFA PRATAMA');
    expect(item.interviewCode, 'INT-2026-001');
  });

  test('PlacementPersonnelItem parses listTable14 row correctly', () {
    final row = <String, Object?>{
      'DT_RowId': 'wait_88',
      '1': 'CITRA LESTARI',
      '2': 'OPERATOR',
      '4': 'PROJECT MALL KOTA KASABLANKA',
      '5': '<a href="/surat-tugas/88.pdf">Unduh</a>',
      '8': '<label class="badge badge-info">Waiting Approval</label>',
    };
    final item = PlacementPersonnelItem.fromDataTableRow(row);
    expect(item.id, 'wait_88');
    expect(item.candidateName, 'CITRA LESTARI');
    expect(item.positionName, 'OPERATOR');
    expect(item.projectName, 'PROJECT MALL KOTA KASABLANKA');
    expect(item.status, 'Waiting Approval');
    expect(item.suratTugasDownloadUrl, '/surat-tugas/88.pdf');
  });

  test('PlacementDraft formats FormData map to match backend contract', () {
    const draft = PlacementDraft(
      projectId: 'PRJ-101',
      lokasiProject: 'Lobby Tower A',
      positionId: 'POS-5',
      quota: '10',
      tanggal: '2026-11-01',
      timeStart: '07:30',
      timeEnd: '16:30',
    );
    final map = draft.toFormDataMap();
    expect(map['projectId'], 'PRJ-101');
    expect(map['lokasiProject'], 'Lobby Tower A');
    expect(map['positionId'], 'POS-5');
    expect(map['kuotaApplicant'], '10');
    expect(map['tanggal'], '2026-11-01');
    expect(map['timeStart'], '07:30');
    expect(map['timeEnd'], '16:30');
  });

  test('JobVacancyItem formats pdfReportUrl and parses applicantCount', () {
    const vacancy = JobVacancyItem(
      id: '105',
      code: 'HK-CS-2026-001',
      period: '2026-10-01 s/d 2026-10-31',
      applicantSummary: '175 Pelamar',
      status: 'Aktif',
      createdAt: '2026-10-01',
    );
    expect(vacancy.pdfReportUrl, contains('/advertisement/pdf/105'));
    expect(vacancy.applicantCount, 175);
    expect(vacancy.qrCodeUrl, contains('ADVERT-105.png'));
  });

  test('PlacementScheduleItem parses listTable13 production row with html link', () {
    final row = <String, Object?>{
      'DT_RowId': '212',
      '0': 1,
      '1': '<div class="btn-group" role="group" aria-label="Action">\r\n'
          '<a href="https://ops.hk-indonesia.id/hkjobs/pakelarin/detailpenempatan/212">PENEMPATAN_212</a>\r\n'
          '</div>',
      '2': 'CIREBON SUPER BLOK',
      '3': '1',
      '4': 'OPERATOR - CLEANING SERVICE',
      '5': '21-10-2026',
      '6': '<button onclick="editPenempatanschedule(212)"></button>',
    };
    final item = PlacementScheduleItem.fromDataTableRow(row);
    expect(item.id, '212');
    expect(item.code, 'PENEMPATAN_212');
    expect(item.projectName, 'CIREBON SUPER BLOK');
    expect(item.quota, '1');
    expect(item.positionName, 'OPERATOR - CLEANING SERVICE');
    expect(item.date, '21-10-2026');
  });

  test('HtmlCellParser parses list-based row payload cleanly', () {
    const raw = '{"recordsTotal":1,"recordsFiltered":1,"data":[["1","PENEMPATAN_100","SAFFRON"]]}';
    final parsed = HtmlCellParser.parseDataTablePayload(raw);
    expect(parsed.totalRecords, 1);
    expect(parsed.rows.length, 1);
    expect(parsed.rows.first['1'], 'PENEMPATAN_100');
  });
}

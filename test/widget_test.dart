import 'package:flutter_test/flutter_test.dart';
import 'package:hkjobs_mobile/core/widgets/hk_form_widgets.dart';
import 'package:hkjobs_mobile/features/academy/domain/academy_models.dart';
import 'package:hkjobs_mobile/features/interview/domain/interview_models.dart';

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
}

import 'package:flutter/foundation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/html_cell_parser.dart';

enum RecruitmentSubTab {
  vacancies('Lowongan'),
  onProcess('Diproses'),
  approved('Diterima'),
  rejected('Ditolak'),
  newComers('Pelamar baru'),
  existing('Eksisting');

  const RecruitmentSubTab(this.label);
  final String label;
}

@immutable
class JobVacancyItem {
  const JobVacancyItem({
    required this.id,
    required this.code,
    required this.period,
    required this.applicantSummary,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String period;
  final String applicantSummary;
  final String status;
  final String createdAt;

  String get qrCodeUrl => '${ApiEndpoints.qrCodeBaseUrl}ADVERT-$id.png';

  factory JobVacancyItem.fromDataTableRow(Map<String, Object?> row) {
    final id = (row['DT_RowId'] ?? '').toString();
    return JobVacancyItem(
      id: id,
      code: HtmlCellParser.stripHtml(row['1']),
      period: HtmlCellParser.stripHtml(row['2']),
      applicantSummary: HtmlCellParser.stripHtml(row['5']),
      status: HtmlCellParser.stripHtml(row['9']),
      createdAt: HtmlCellParser.stripHtml(row['11']),
    );
  }
}

@immutable
class VacancyApplicationItem {
  const VacancyApplicationItem({
    required this.userAdvertId,
    required this.applicantId,
    required this.fullName,
    required this.nik,
    required this.birthDate,
    required this.gender,
    required this.phone,
    required this.heightCm,
    required this.weightKg,
    required this.maritalStatus,
    required this.email,
    required this.city,
    required this.education,
    required this.lastPosition,
    required this.experience,
    required this.applyDate,
    required this.documentUrls,
    required this.statusText,
  });

  final String userAdvertId;
  final String applicantId;
  final String fullName;
  final String nik;
  final String birthDate;
  final String gender;
  final String phone;
  final String heightCm;
  final String weightKg;
  final String maritalStatus;
  final String email;
  final String city;
  final String education;
  final String lastPosition;
  final String experience;
  final String applyDate;
  final List<String> documentUrls;
  final String statusText;

  factory VacancyApplicationItem.fromDataTableRow(
    Map<String, Object?> row, {
    required String defaultStatus,
  }) {
    final rowId = (row['DT_RowId'] ?? '').toString();
    final extractedAppId =
        HtmlCellParser.extractFirstFunctionArg(row['1'], 'editShowPelamar') ??
            HtmlCellParser.extractTrailingPathId(row['1']) ??
            rowId;

    return VacancyApplicationItem(
      userAdvertId: rowId,
      applicantId: extractedAppId,
      fullName: HtmlCellParser.stripHtml(row['1']),
      nik: HtmlCellParser.stripHtml(row['2']),
      birthDate: HtmlCellParser.stripHtml(row['3']),
      gender: HtmlCellParser.stripHtml(row['4']),
      phone: HtmlCellParser.stripHtml(row['5']),
      heightCm: HtmlCellParser.stripHtml(row['6']),
      weightKg: HtmlCellParser.stripHtml(row['7']),
      maritalStatus: HtmlCellParser.stripHtml(row['10']),
      email: HtmlCellParser.stripHtml(row['11']),
      city: HtmlCellParser.stripHtml(row['14']),
      education: HtmlCellParser.stripHtml(row['17']),
      lastPosition: HtmlCellParser.stripHtml(row['18']),
      experience: HtmlCellParser.stripHtml(row['19']),
      applyDate: HtmlCellParser.stripHtml(row['20']),
      documentUrls: HtmlCellParser.extractHrefs(row['21']),
      statusText: row.containsKey('22')
          ? HtmlCellParser.stripHtml(row['22'])
          : defaultStatus,
    );
  }
}

@immutable
class MasterApplicantItem {
  const MasterApplicantItem({
    required this.applicantId,
    required this.fullName,
    required this.experienceOrDate,
    required this.status,
    required this.documentUrls,
  });

  final String applicantId;
  final String fullName;
  final String experienceOrDate;
  final String status;
  final List<String> documentUrls;

  factory MasterApplicantItem.fromDataTableRow(
    Map<String, Object?> row, {
    required bool isExisting,
  }) {
    final id = (row['DT_RowId'] ?? '').toString();
    if (isExisting) {
      return MasterApplicantItem(
        applicantId: id,
        fullName: HtmlCellParser.stripHtml(row['1']),
        experienceOrDate: HtmlCellParser.stripHtml(row['3']),
        status: HtmlCellParser.stripHtml(row['4']),
        documentUrls: HtmlCellParser.extractHrefs(row['2']),
      );
    }
    return MasterApplicantItem(
      applicantId: id,
      fullName: HtmlCellParser.stripHtml(row['1']),
      experienceOrDate: HtmlCellParser.stripHtml(row['2']),
      status: HtmlCellParser.stripHtml(row['5']),
      documentUrls: HtmlCellParser.extractHrefs(row['3']),
    );
  }
}

@immutable
class ApplicantFullProfile {
  const ApplicantFullProfile({
    required this.id,
    required this.fullName,
    required this.nik,
    required this.phone,
    required this.email,
    required this.birthPlace,
    required this.birthDate,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.education,
    required this.positionName,
    required this.workExperience,
    required this.maritalStatus,
    required this.hasTattoo,
    required this.hasPiercing,
    required this.address,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.statusActive,
    required this.documents,
  });

  final String id;
  final String fullName;
  final String nik;
  final String phone;
  final String email;
  final String birthPlace;
  final String birthDate;
  final String gender;
  final String heightCm;
  final String weightKg;
  final String education;
  final String positionName;
  final String workExperience;
  final String maritalStatus;
  final String hasTattoo;
  final String hasPiercing;
  final String address;
  final String district;
  final String city;
  final String province;
  final String postalCode;
  final String statusActive;
  final Map<String, String> documents;

  factory ApplicantFullProfile.fromJson(Map<String, Object?> json) {
    String str(String key) {
      final v = json[key]?.toString().trim() ?? '';
      return v.isEmpty ? '-' : v;
    }

    final firstName = str('first_name_applicant');
    final lastName = str('last_name_applicant');
    final combinedName = '$firstName $lastName'.replaceAll('-', '').trim();

    final docs = <String, String>{};
    void addDoc(String label, String folder, String key) {
      final file = json[key]?.toString().trim() ?? '';
      if (file.isNotEmpty && file != 'null') {
        docs[label] = '${ApiEndpoints.assetsBaseUrl}$folder/$file';
      }
    }

    addDoc('Selfie KTP', 'ktp', 'selfie_ktp_applicant');
    addDoc('Ijazah pendidikan', 'document/last_education',
        'photo_education_applicant');
    addDoc('Paklaring kerja', 'document/last_job', 'photo_job_applicant');
    addDoc('SKCK', 'skck', 'upload_skck_applicant');
    addDoc('SIO', 'sio', 'upload_sio_applicant');
    addDoc('SIM', 'sim', 'upload_sim_applicant');
    addDoc('Sertifikat kompetensi', 'certificate',
        'upload_certificate_applicant');
    addDoc('Sertifikat vaksin', 'certificate_vaccine',
        'upload_certificate_vaccine_applicant');
    addDoc('Kartu Keluarga (KK)', 'kk', 'upload_kk_applicant');

    return ApplicantFullProfile(
      id: str('id_applicant'),
      fullName: combinedName.isEmpty ? 'Pelamar HK' : combinedName.toUpperCase(),
      nik: str('nik_number'),
      phone: str('phone_applicant'),
      email: str('email_applicant'),
      birthPlace: str('birth_at_applicant'),
      birthDate: str('birth_date_applicant'),
      gender: str('gender_applicant'),
      heightCm: str('height_applicant'),
      weightKg: str('weight_applicant'),
      education: str('last_education_applicant'),
      positionName: str('nama_position'),
      workExperience: str('work_experience_applicant'),
      maritalStatus: str('marital_status_applicant'),
      hasTattoo: str('have_tatoo_applicant'),
      hasPiercing: str('ear_piercing_applicant'),
      address: str('address_details_applicant'),
      district: str('dis_name'),
      city: str('city_name'),
      province: str('prov_name'),
      postalCode: str('postal_code'),
      statusActive: str('isactive_applicant'),
      documents: docs,
    );
  }
}

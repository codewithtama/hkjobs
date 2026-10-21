abstract final class ApiEndpoints {
  static const String baseUrl = 'https://ops.hk-indonesia.id/hkjobs/';
  static const String assetsBaseUrl =
      'https://ops.hk-indonesia.id/assetshkjobs/';
  static const String qrCodeBaseUrl =
      'https://ops.hk-indonesia.id/assetshkjobs/qrcode/';

  // Auth & Dashboard
  static const String login = '';
  static const String logout = 'auth/logout';
  static const String dashboard = 'dashboard';
  static const String dashboardFilter = 'dashboard/dataDashboardFilter';

  // Organization & Master Data
  static const String adminListTable = 'admin/listTable';
  static String adminEditDetail(String id) => 'admin/editAdminMaster/$id';
  static const String adminUpdate = 'admin/updateAdminMaster';
  static const String karyawanListTable = 'Karyawan/listTable';
  static const String branchListTable = 'institut/listTable';
  static String branchEditDetail(String id) => 'institut/editInstitut/$id';
  static const String positionListTable = 'institut/listTable3';
  static String positionEditDetail(String id) =>
      'institut/editInstitutPosition/$id';

  // Recruitment (HK Jobs)
  static const String advertisementListTable = 'advertisement/listTable';
  static String advertisementApplicantsTable(String advertId) =>
      'advertisement/listTable2/$advertId';
  static const String advertisementApprovedTable =
      'advertisement/listTableApproved';
  static const String advertisementOnProcessTable =
      'advertisement/listTableOnProcess';
  static const String advertisementNotApprovedTable =
      'advertisement/listTableNotApproved';
  static String advertisementDetailJson(String id) =>
      'advertisement/editAdminMaster/$id';
  static String applicantInfoJson(String applicantId) =>
      'advertisement/infoPelamar/$applicantId';
  static String advertUserEditJson(String advertUserId) =>
      'advertisement/editAdvertUser/$advertUserId';
  static const String approveApplicantToSchedule =
      'advertisement/updatedApprovetoSchedule';
  static const String updateAdvertisementApproval =
      'advertisement/updateStatusApproval';
  static const String applicantNewComerTable = 'applicant/listTable';
  static const String applicantExistingTable = 'applicant/listTable2';
  static String advertisementFilterTable({
    required String cabang,
    required String startDate,
    required String endDate,
  }) =>
      'advertisement/listTableAdvertisementListFilter/$cabang/$startDate/$endDate';
  static String applicantFilterTable(String opsiFilter) =>
      'applicant/listTableFilter/$opsiFilter';

  // Interview
  static const String interviewListTable = 'interview/listTable';
  static String interviewerScheduleTable(String adminId) =>
      'interview/listTableInterviewer/$adminId';
  static String interviewParticipantsTable(String interviewId) =>
      'interview/listTable2/$interviewId';
  static String interviewFilterTable({
    required String cabang,
    required String startDate,
    required String endDate,
  }) => 'interview/listTable4/$cabang/$startDate/$endDate';
  static const String interviewConfirmedTable = 'Interview/listTableConfirmed';
  static const String interviewCanceledTable = 'Interview/listTableCanceled';
  static const String interviewPassedTable = 'interview/listTablePassed';
  static const String interviewFailedTable = 'Interview/listTableFailed';
  static String interviewInfoJson(String id) => 'interview/infoInterview/$id';
  static String interviewSubmitEvaluation = 'Advertisement/updateAdvertUser';

  // Academy, Training, PKL & Penempatan
  static const String trainingListTable = 'training/listTable';
  static String trainingParticipantsTable(String trainingId) =>
      'training/listTable2/$trainingId';
  static const String trainingOnlinePassedTable = 'training/listTable4';
  static const String trainingOnlineFailedTable = 'training/listTable5';
  static const String trainingOfflineFailedTable = 'training/listTable6';
  static const String trainingOfflinePassedTable = 'training/listTable7';
  static const String trainingQuestionsTable = 'training/listTable8';
  static String trainingParticipantStatusJson(String trainingListId) =>
      'training/editStatusPelamar/$trainingListId';
  static const String trainingUpdatePassed = 'training/updateLolosTraining';
  static const String trainingUpdateFailed =
      'training/updateTidakLolosTraining';
  static const String trainingOnlineReset = 'training/updateAlasan';
  static const String trainingOnlineBypass = 'training/updateAlasanOnlineLolos';

  static const String pklWaitingTable = 'pakelarin/listTable';
  static const String pklScheduleTable = 'pakelarin/listTable2';
  static const String pklPassedTable = 'pakelarin/listTable5';
  static const String pklMentorTable = 'pakelarin/listTable6';
  static const String placementWaitingTable = 'pakelarin/listTable7';
  static const String placementScheduleTable = 'pakelarin/listTable13';
  static String placementPersonnelTable(String placementId) =>
      'pakelarin/listTable14/$placementId';
  static const String placementScheduleCreate =
      'pakelarin/createSchedulePenempatan';
  static const String placementScheduleForm =
      'pakelarin/createpenempatanschedule';
  static const String placementAssignCandidate = 'pakelarin/updatePenempatan';
  static const String placementUpdateSuratTugas = 'pakelarin/updateSuratTugas';
  static String placementSuratTugasDownload(String id) =>
      'pakelarin/suratTugas/$id';
  static const String placementBypassToOps =
      'pakelarin/updateByPasstoOpsBySigit';
  static String placementDetailJson(String id) =>
      'pakelarin/editPenempatanSchedule/$id';
  static const String fieldManagerTable = 'pakelarin/listTable19';
  static const String psikotesTable = 'psikotes/listTable';

  // Form create / update
  static const String adminCreate = 'admin-carefast/create';
  static const String vacancyCreate = 'advertisement/create';
  static const String vacancyUpdate = 'advertisement/updateAdminMaster';
  static const String vacancyBranchLocations =
      'advertisement/optionCabangKode/';
  static const String vacancyCodePrefix = 'advertisement/optionKode/';
  static const String interviewCreate = 'interview/create';
  static const String interviewLocations = 'interview/optionLokasi/';
  static const String interviewLocationDetail = 'interview/optionDetailCabang/';
  static const String trainingCreate = 'training/create';
  static const String trainingLocations = 'training/optionLokasi/';
  static const String trainingLocationDetail = 'training/optionDetailCabang/';
  static const String trainingScheduleTable = 'training/listTable';
  static const String academyAccountsTable = 'listloginapps/listTable';
}

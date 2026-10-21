abstract final class AppStrings {
  static const String appTitle = 'HKJobs Ops';
  static const String companySubtitle =
      'Hygiene Kleen • PT Peduli Cepat Internasional';

  // Auth
  static const String loginTitle = 'Masuk panel operasional';
  static const String loginSubtitle =
      'Gunakan nomor telepon akun Admin, Interviewer, atau Trainer HKJobs.';
  static const String phoneLabel = 'Nomor telepon / ID akses';
  static const String phoneHint = 'Contoh: 62001';
  static const String passwordLabel = 'Kata sandi';
  static const String passwordHint = 'Masukkan kata sandi';
  static const String signInButton = 'Masuk sekarang';
  static const String quickRolePresetTitle = 'Akun cepat (sesuai peran sistem)';
  static const String presetSuperAdmin = 'Super Admin (62001)';
  static const String presetInterviewer = 'Interviewer (62002)';
  static const String presetTrainer = 'Trainer (62003)';
  static const String signingInMessage =
      'Memverifikasi kredensial & memuat hak akses peran...';
  static const String logoutLabel = 'Keluar sesi';

  // Navigation
  static const String navDashboard = 'Ringkasan';
  static const String navRecruitment = 'Rekrutmen';
  static const String navInterview = 'Interview';
  static const String navAcademy = 'Academy & PKL';
  static const String navMaster = 'Organisasi';

  // Dashboard
  static const String dashboardHeader = 'Analitik rekrutmen & operasional';
  static const String loadingDashboard =
      'Mengambil statistik rekrutmen & interview dari server HKJobs...';
  static const String filterDateRange = 'Filter rentang tanggal';
  static const String resetFilter = 'Reset semua periode';
  static const String sectionVacancyFunnel = 'Status pelamar lowongan kerja';
  static const String sectionInterviewFunnel =
      'Pipeline jadwal & hasil interview';
  static const String sectionApplicantPool = 'Populasi kandidat aktif';
  static const String sectionRegionalBranches = 'Kantor cabang operasional';
  static const String statusApproved = 'Diterima';
  static const String statusOnProcess = 'Diproses';
  static const String statusRejected = 'Ditolak';
  static const String statusConfirmed = 'Konfirmasi hadir';
  static const String statusCanceled = 'Batal hadir';
  static const String statusPassed = 'Lolos interview';
  static const String statusFailed = 'Gagal interview';
  static const String labelNewComer = 'Pelamar baru (New comer)';
  static const String labelExisting = 'Eksisting (Pernah bekerja)';
  static const String labelActiveApplicants = 'Total pelamar aktif';
  static const String labelSchedules = 'Total jadwal interview';

  // Recruitment
  static const String tabVacancies = 'Lowongan (105)';
  static const String tabOnProcess = 'Diproses';
  static const String tabApproved = 'Diterima';
  static const String tabRejected = 'Ditolak';
  static const String tabNewComers = 'Pelamar baru';
  static const String tabExisting = 'Pelamar eksisting';
  static const String loadingVacancies =
      'Memuat daftar lowongan kerja aktif...';
  static const String loadingApplicants = 'Memuat data kandidat & dokumen...';
  static const String loadingApplicantDetail =
      'Memuat biodata lengkap & berkas dokumen pelamar...';
  static const String searchPlaceholder =
      'Cari kode, nama pelamar, atau kota...';
  static const String emptyListTitle = 'Belum ada data ditemukan';
  static const String emptyListSubtitle =
      'Coba ubah kata kunci pencarian atau muat ulang halaman ini.';
  static const String viewQrButton = 'Lihat QR';
  static const String viewApplicantsButton = 'Lihat pelamar';
  static const String viewCandidatesButton = 'Lihat peserta';
  static const String reviewApplicantButton = 'Review berkas';
  static const String detailApplicantButton = 'Biodata & dokumen';

  // Interview
  static const String tabInterviewSchedules = 'Jadwal';
  static const String tabInterviewConfirmed = 'Konfirmasi';
  static const String tabInterviewPassed = 'Lolos';
  static const String tabInterviewFailed = 'Gagal';
  static const String tabInterviewCanceled = 'Batal';
  static const String loadingInterviews =
      'Memuat jadwal interview & daftar kandidat...';
  static const String evaluateCandidateTitle =
      'Formulir penilaian interviewer (Skor otomatis)';
  static const String submitEvaluationButton = 'Simpan penilaian interview';
  static const String passingThresholdNote =
      'Ambang kelulusan otomatis: Skor ≥ 65 = Lolos (Passed), ≤ 64 = Gagal (Failed).';

  // Academy, PKL & Penempatan
  static const String tabTrainingOffline = 'Training offline';
  static const String tabPlacementWaiting = 'Waiting penempatan';
  static const String tabPlacementSchedules = 'Jadwal penempatan';
  static const String tabAcademyNus = 'Akun NUS Academy';
  static const String tabFieldManagers = 'Akun FM';
  static const String tabPsikotes = 'Bank psikotes';
  static const String loadingAcademy =
      'Memuat data HK Academy, jadwal training, dan penempatan proyek...';
  static const String markPassedButton = 'Loloskan';
  static const String markFailedButton = 'Gagalkan';

  // Master & Organization
  static const String tabEmployees = 'Karyawan HK';
  static const String tabPositions = 'Posisi jabatan';
  static const String tabBranches = 'Kantor cabang';
  static const String tabAdmins = 'Admin & penilai';
  static const String loadingOrganization =
      'Memuat direktori karyawan, posisi jabatan, dan kantor cabang...';

  // Generic Actions
  static const String retryButton = 'Coba lagi';
  static const String closeButton = 'Tutup';
  static const String cancelButton = 'Batal';
  static const String saveButton = 'Simpan';
}

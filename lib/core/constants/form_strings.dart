abstract final class FormStrings {
  // Umum
  static const String save = 'Simpan';
  static const String saving = 'Menyimpan data ke server...';
  static const String loadingForm = 'Memuat pilihan form dari server HKJobs...';
  static const String savedSuccess = 'Data berhasil disimpan.';
  static const String selectPlaceholder = 'Pilih salah satu';
  static const String selectPlaceholderMulti = 'Pilih satu atau lebih';
  static const String pickerSearch = 'Cari pilihan...';
  static const String pickerDone = 'Selesai';
  static const String pickerEmpty = 'Pilihan tidak ditemukan.';
  static const String pickDate = 'Pilih tanggal';
  static const String pickTime = 'Pilih jam';
  static const String pickImage = 'Pilih gambar';
  static const String imageNotSelected = 'Belum ada gambar dipilih';
  static const String imageTooLarge = 'Ukuran gambar maksimal 2 MB.';
  static const String imageReadFailed = 'Gambar tidak dapat dibaca.';
  static const String addRow = 'Tambah baris';
  static const String removeRow = 'Hapus baris';
  static const String quota = 'Kuota';
  static const String optionalSuffix = '(opsional)';

  static String required(String label) => '$label wajib diisi.';

  // Admin
  static const String createAdminTitle = 'Tambah admin / penilai';
  static const String adminName = 'Nama';
  static const String adminEmail = 'Email';
  static const String adminPhone = 'No. HP (dipakai untuk login)';
  static const String adminPassword = 'Kata sandi';
  static const String adminPasswordConfirm = 'Konfirmasi kata sandi';
  static const String adminRole = 'Tingkat';
  static const String adminBranch = 'Kantor cabang';
  static const String adminPosition = 'Jabatan';
  static const String adminStatus = 'Status';
  static const String adminPhoto = 'Foto (opsional, maks 2 MB)';
  static const String adminPasswordMismatch =
      'Konfirmasi kata sandi tidak sama.';
  static const String addAdminAction = 'Tambah admin';

  // Lowongan
  static const String createVacancyTitle = 'Buat lowongan';
  static const String editVacancyTitle = 'Ubah lowongan';
  static const String vacancyBranch = 'Kantor cabang';
  static const String vacancySubBranch = 'Kantor cabang pembantu';
  static const String vacancyCodePrefix = 'Awalan kode';
  static const String vacancyCodeSuffix = 'Lanjutan kode (mis. OKTOBER_2026)';
  static const String vacancyCode = 'Kode lowongan';
  static const String vacancyBanner = 'Banner (opsional, maks 2 MB)';
  static const String vacancyIcon = 'Ikon (wajib, maks 2 MB)';
  static const String vacancyPosition = 'Posisi pekerjaan';
  static const String vacancyDescription = 'Deskripsi pekerjaan';
  static const String vacancyCities = 'Kota penempatan';
  static const String vacancyExperience = 'Pengalaman';
  static const String vacancyStart = 'Tanggal mulai';
  static const String vacancyEnd = 'Tanggal berakhir';
  static const String vacancyDateOrder =
      'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
  static const String createVacancyAction = 'Buat lowongan';
  static const String editVacancyAction = 'Ubah lowongan';
  static const String loadingVacancyDetail = 'Memuat data lowongan...';

  // Interview & Training
  static const String createInterviewTitle = 'Buat jadwal interview';
  static const String createTrainingTitle = 'Buat jadwal training';
  static const String createInterviewAction = 'Buat jadwal';
  static const String interviewVacancy = 'Kode lowongan';
  static const String interviewLocation = 'Lokasi interview';
  static const String trainingBranch = 'Kantor cabang';
  static const String trainingLocation = 'Lokasi training';
  static const String locationArea = 'Area lokasi';
  static const String locationAddress = 'Alamat lokasi';
  static const String loadingLocations = 'Memuat lokasi...';
  static const String interviewDate = 'Tanggal interview';
  static const String timeStart = 'Jam mulai';
  static const String timeEnd = 'Jam selesai';
  static const String interviewerRows = 'Kuota per interviewer';
  static const String trainerRows = 'Kuota per trainer';
  static const String interviewerLabel = 'Interviewer';
  static const String trainerLabel = 'Trainer';
  static const String quotaRowsRequired =
      'Isi minimal satu baris dengan kuota dan penilai.';
  static const String trainingCode = 'Kode training';
  static const String trainingRank = 'Tingkat kursus';
  static const String trainingPosition = 'Posisi pekerjaan';
  static const String trainingStart = 'Tanggal mulai';
  static const String trainingEnd = 'Tanggal selesai';
  static const String trainingCustomAddress = 'Gunakan alamat kustom';
  static const String trainingCustomAddressField = 'Alamat training';
  static const String trainingDateOrder =
      'Tanggal selesai tidak boleh sebelum tanggal mulai.';

  // Aksi training
  static const String trainingSchedulesTab = 'Jadwal training';
  static const String loadingTrainingSchedules = 'Memuat jadwal training...';
  static const String participantsTitle = 'Peserta training';
  static const String loadingParticipants = 'Memuat daftar peserta training...';
  static const String passAction = 'Loloskan';
  static const String failAction = 'Gagalkan';
  static const String reasonLabel = 'Alasan / catatan';
  static const String reasonRequired = 'Alasan wajib diisi.';
  static const String confirmPassTitle = 'Loloskan peserta ini?';
  static const String confirmFailTitle = 'Gagalkan peserta ini?';
  static const String irreversibleNote =
      'Tindakan ini tidak dapat dibatalkan dari aplikasi.';
  static const String createTrainingAction = 'Buat jadwal training';

  // Penempatan
  static const String createPlacementTitle = 'Buat jadwal penempatan';
  static const String createPlacementAction = 'Buat jadwal penempatan';
  static const String placementProject = 'Lokasi project';
  static const String placementLocation = 'Alamat / area project';
  static const String placementPosition = 'Nama posisi';
  static const String placementQuota = 'Kuota penempatan';
  static const String placementDate = 'Tanggal penempatan';
  static const String placementTimeStart = 'Jam mulai';
  static const String placementTimeEnd = 'Jam selesai';
  static const String placementPersonnelTitle = 'Personel penempatan';
  static const String loadingPersonnel = 'Memuat personel penempatan...';
  static const String vacancyApplicantsTitle = 'Pelamar lowongan';
  static const String loadingVacancyApplicants = 'Memuat pelamar lowongan...';
  static const String interviewParticipantsTitle = 'Peserta interview';
  static const String loadingInterviewParticipants =
      'Memuat peserta jadwal interview...';

  // QR
  static const String scanTitle = 'Pindai QR';
  static const String scanHint =
      'Arahkan kamera ke QR lowongan atau jadwal interview.';
  static const String scanLoading = 'Mencari data dari QR...';
  static const String scanUnknown = 'QR ini bukan QR lowongan atau jadwal HKJobs.';
  static const String scanCameraDenied =
      'Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.';
  static const String scanCameraError = 'Kamera tidak dapat dibuka.';
  static const String scanAgain = 'Pindai lagi';
  static const String scanVacancyHeader = 'Lowongan kerja';
  static const String scanInterviewHeader = 'Jadwal interview';
  static const String scanAction = 'Pindai QR';
}

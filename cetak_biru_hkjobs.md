# Cetak Biru (System Blueprint) HKJobs & HK Academy

Dokumen ini adalah hasil rekayasa balik (*reverse-engineering*) langsung dari sistem produksi **`https://ops.hk-indonesia.id/hkjobs/`** menggunakan akun Super Admin (`62001` — **DIMAS ALFA PRATAMA**) serta pengujian lintas peran (`62002` Interviewer & `62003` Trainer).

---

## 1. Gambaran Umum Sistem

Website **`ops.hk-indonesia.id/hkjobs`** adalah **Web Backoffice / Admin CMS** (berbasis CodeIgniter 3, Bootstrap 4, dan Server-Side DataTables) milik **Hygiene Kleen (PT Peduli Cepat Internasional / Carefast)** yang mengelola siklus hidup tenaga kerja dari hulu ke hilir:

1. **Umum & Master Organisasi**: Kantor cabang, lokasi interview, posisi jabatan, standar kriteria fisik/dokumen per posisi, data karyawan eksisting, dan proyek klien (*Manpower Planning*).
2. **HK Jobs (Rekrutmen & Seleksi)**: Pendaftaran pelamar (*New Comer* & *Existing*), publikasi lowongan kerja (dengan QR Code), psikotes online, penjadwalan interview multi-interviewer, dan penilaian kelulusan interview.
3. **HK Academy (Onboarding, Pelatihan, PKL, & Penempatan)**: Konversi pelamar lolos menjadi peserta *Academy* (mendapat **NUS Pelamar**), materi *e-learning* berjenjang (*Course → Module → Topic → Activity*), ujian *Training Online* & *Training Offline*, *Praktik Kerja Lapangan* (PKL) bersama Mentor proyek, hingga penerbitan **Surat Tugas Penempatan** yang divalidasi oleh *Field Manager* (FM) sebelum masuk ke sistem operasional (**NUC Karyawan**).

---

## 2. Peta Aktor & Hak Akses (7 Peran)

Berdasarkan tabel `admin_master`, `applicant`, `login_apps`, `mentor`, dan `fieldmanager`, terdapat **7 peran pengguna** di dalam ekosistem ini:

| # | Peran (Role) | Identitas Login | Kanal Saat Ini | Tugas Utama |
|---|---|---|---|---|
| 1 | **Super Admin / Admin Cabang** | `phone` (`62001`) + Password | Web (`hkjobs`) | Mengelola seluruh master data, lowongan, psikotes, menyetujui berkas pelamar, membuat jadwal interview/training/PKL/penempatan, & melakukan *bypass* status. |
| 2 | **Supervisor** | `phone` + Password | Web (`hkjobs`) | Monitoring laporan rekrutmen cabang, *approval* lowongan, dan pengawasan *pipeline*. |
| 3 | **Interviewer** | `phone` (`62002`) + Password | Web (`hkjobs/interviewer/{id}`) / Mobile | Melihat jadwal interview yang ditugaskan, memindai/cek kehadiran QR kandidat, memverifikasi fisik & dokumen asli, serta menilai kelulusan interview. |
| 4 | **Trainer** | `phone` (`62003`) + Password | Web (`hkjobs/training`) / Mobile | Mengelola kelas *Training Offline*, absensi QR peserta, dan memberikan nilai/status kelulusan *Training Offline*. |
| 5 | **Pelamar (Candidate)** | `phone_applicant` / Email + Password | Aplikasi Mobile (HK Jobs) | Registrasi profil & unggah 12 dokumen, cari/lamar lowongan (atau scan QR Loker), kerjakan Psikotes, konfirmasi kehadiran interview, & scan QR hadir interview. |
| 6 | **Peserta Academy (Trainee)** | `nus_pelamar` (mis. `A1`, `A19`) + Password | Aplikasi Mobile (HK Academy) | Login pasca-lolos interview, mempelajari *Course/Module/Topic/Activity*, kuis *Training Online*, ujian *Training Offline*, absensi QR PKL, unduh Surat Pengantar PKL & Surat Tugas Penempatan. |
| 7 | **Mentor PKL & Field Manager (FM)** | `nuc_login` / `fm_phone` (`08485354`) + Password | Aplikasi Mobile Operasional | **Mentor**: Menilai *checklist* pekerjaan peserta PKL di proyek. **FM**: Menerima dan mengonfirmasi personel baru yang ditempatkan di proyek klien. |

---

## 3. Alur Bisnis End-to-End (Pipeline Rekrutmen s.d. Penempatan)

```mermaid
flowchart TD
    subgraph P1["1. Master & Lowongan (Admin)"]
        M1["Master Cabang, Posisi, & Kriteria Fisik/Dokumen"] --> M2["Buat Lowongan Kerja (Generate QRADVERT)"]
        M2 --> M3["Buat Jadwal Interview & Kuota Interviewer (Generate QRSCHEDULE)"]
    end

    subgraph P2["2. HK Jobs (Pelamar & Seleksi)"]
        A1["Pelamar Registrasi + Upload KTP & Dokumen"] --> A2["Lamar Lowongan + Kerjakan Psikotes Online"]
        A2 --> A3{"Review Berkas & Skor Psikotes oleh Admin"}
        A3 -- "Ditolak (Not Approved)" --> A4["Status: Ditolak + Alasan"]
        A3 -- "Diterima (Approved)" --> A5["Masuk Jadwal Interview"]
        A5 --> A6{"Konfirmasi Hadir oleh Pelamar"}
        A6 -- "Batal" --> A7["Daftar Cancel Interview"]
        A6 -- "Konfirmasi & Scan QR Hadir" --> A8["Penilaian Fisik, Dokumen, & Kompetensi oleh Interviewer"]
        A8 -- "Tidak Lolos" --> A9["Daftar Gagal Interview"]
        A8 -- "Lolos Interview" --> A10["Generate Akun HK Academy (NUS Pelamar, mis. A19)"]
    end

    subgraph P3["3. HK Academy (Training & PKL)"]
        A10 --> T1["Training Online (Course -> Module -> Topic -> Activity/Quiz)"]
        T1 --> T2{"Lolos Training Online?"}
        T2 -- "Gagal" --> T2R["Admin: Reset Online / Bypass Lolos"]
        T2 -- "Lolos / Bypass" --> T3["Jadwal Training Offline + Soal Post-Test (QR TRAINING)"]
        T3 --> T4{"Penilaian Trainer Offline"}
        T4 -- "Lolos" --> K1["Waiting List PKL"]
        K1 -- "Bypass Penempatan" --> D1
        K1 -- "Assign Jadwal, Lokasi Proyek & Mentor" --> K2["Pelaksanaan PKL (QR Absensi + Surat Pengantar PDF)"]
        K2 --> K3{"Evaluasi Skor Pekerjaan PKL oleh Mentor"}
        K3 -- "Perlu Tambahan Waktu" --> K4["Extend PKL"]
        K3 -- "Lolos PKL (Grade)" --> D1["Waiting List Penempatan"]
    end

    subgraph P4["4. Penempatan & Operasional"]
        D1 --> D2["Assign Jadwal Penempatan Proyek + Kuota"]
        D2 --> D3["Terbit Surat Tugas + QR Penempatan"]
        D3 --> D4["Konfirmasi Field Manager (FM) / Bypass to Ops"]
        D4 --> D5["Menjadi Karyawan Aktif HK (NUC Karyawan)"]
    end
```

---

## 4. Peta Modul, Halaman, & Endpoint Sistem (49 Halaman)

### A. Kategori: UMUM (Master Data & Organisasi)

| Modul / Menu | URL Route | Endpoint DataTables / Action | Fungsi & Field Utama |
|---|---|---|---|
| **Halaman Utama (Dashboard)** | `/dashboard` | `POST /dashboard/dataDashboardFilter` | Filter `tgl1` s.d. `tgl2`. Menampilkan ringkasan cabang (`RC-HO`, `RC-JKT2`, `RC-JABAR`, `RC-JATENG`, `RC-JATIM`, `RC-BALI`, `RC-MEDAN`), total pelamar (2.761 *New Comer*, 19 *Existing*), *funnel* Loker (175 Diterima, 358 *On Process*, 331 Ditolak), *funnel* Interview, Training, & PKL. |
| **Admin HK** | `/admin-carefast`<br>`/admin-carefast/create` | `POST /admin/listTable`<br>`GET /admin/editAdminMaster/{id}`<br>`POST /admin/updateAdminMaster`<br>`POST /admin/deleteAdminMaster/{id}` | Kelola akun internal (`nameAdminMaster`, `emailAdminMaster`, `phoneAdminMaster`, `password`, `roleAdmin` [`Admin`, `Interviewer`, `Supervisor`, `Trainer`], `cabangid`, `jabatanAdmin`, `statusAdminMaster`). |
| **Karyawan HK** | `/karyawan` | `POST /Karyawan/listTable` | Direktori 582 karyawan aktif (`NUC Karyawan`, `Nama Karyawan`, `Nama Project`). |
| **Kantor Cabang & Area Interview** | `/organization`<br>`/organization/create`<br>`/organization/detail/{id}` | `POST /institut/listTable`<br>`GET /institut/editInstitut/{id}`<br>`POST /institut/updateInstitut` | Master cabang (`kode_branch` mis. `HK02`, `nama_branch`, `address`, `area_kantor_cabang`) beserta sub-daftar **Lokasi Area Interview** (`address_kode`, `address_cabang`). |
| **Posisi Pekerjaan** | `/organization/position`<br>`/organization/position/create` | `POST /institut/listTable3`<br>`GET /institut/editInstitutPosition/{id}`<br>`POST /institut/updateInstitutPosition` | 23 posisi pekerjaan (`code_position` mis. `CS-OP`, `CS-GDL`, `nama_position`, `periodic` pengalaman, `level_position` [`BASIC`, dll.], `position_image`). |
| **Kriteria Pekerjaan** | `/organization/criteria`<br>`/organization/criteria/create` | `POST /institut/listTable5`<br>`GET /institut/editJobCriteria/{id}`<br>`POST /institut/updateJobCriteria` | Parameter syarat per posisi: Jenis kelamin & tinggi minimal (`priaHeight`, `perempuanHeight`), `haveTatoo`, `earPiercing`, `minEducation`, rentang usia (`minAgeUmur`..`maxAgeUmur`), `maritalStatus[]`, dan syarat dokumen wajib (`certificateEmployment`, `simPhoto`, `sioPhoto`, `certificateCompetency`, `skckPhoto`, `stnkPhoto`). |
| **FAQ & Kategori** | `/faq`, `/faq/create`<br>`/faq/category`, `/faq/createFaqCat` | `POST /faq/listTable`<br>`POST /faq/listTable2` | Bantuan & tanya-jawab aplikasi (`questionFaq`, `answerFaq`, `categoryFaq[]`, `statusFaq`). |
| **Regulation** | `/regulation`<br>`/regulation/create` | `POST /regulation/listTable`<br>`GET /regulation/editRegulation/{id}` | Peraturan perusahaan / S&K aplikasi (`regulationName`, `regulationTipe`, `regulationDescription`, `regulationStatus`). |
| **ManPower Project** *(Hidden Menu)* | `/project`<br>`/project/create` | `POST /project/upload-excel` | Daftar proyek klien (`kodeProject`, `namaKlien`, `branchId`, `areaProject`, `typeProject`, `tanggalMulai`, `tanggalAkhir`, `Jumlah Man Power`). |

---

### B. Kategori: HK JOBS (Rekrutmen & Seleksi)

| Modul / Menu | URL Route | Endpoint DataTables / Action | Fungsi & Field Utama |
|---|---|---|---|
| **Pelamar Baru & Existing** | `/applicant`<br>`/applicant/existing`<br>`/applicant/listHistory/{id}` | `POST /applicant/listTable` (2.761 data)<br>`POST /applicant/listTable2` (19 data)<br>`GET /applicant/editApplicant/{id}`<br>`POST /applicant/updateApplicant` | Data profil lengkap pelamar, tautan pratinjau dokumen (`last_education`, `sim`, `sio`, `certificate`, `skck`, `ktp`), riwayat lamaran, serta aktivasi/blokir status pelamar. |
| **Lowongan Kerja** | `/advertisement`<br>`/advertisement/create`<br>`/advertisement/detailAdvertisement/{id}`<br>`/advertisement/dataLaporanDetail/{id}` | `POST /advertisement/listTable` (105 data)<br>`POST /advertisement/listTable2/{id}`<br>`POST /advertisement/updatedApprovetoSchedule`<br>`GET /advertisement/pdf/{id}` | Kelola lowongan (`advertisement_code`, `branchId`, `kantorCabangPembantu`, `jobId`, `selectProvince[]` kota penempatan, `optionPengalaman`, `dateStart`..`dateEnd`, banner & icon, QR Code `ADVERT-{id}.png`), cetak PDF laporan *funnel*, dan *review* pelamar (terima ke jadwal interview atau tolak beserta alasan). |
| **Filter Status Pelamar Loker** | `/advertisement/detailApproved`<br>`/advertisement/detailOnProcess`<br>`/advertisement/detailNotApproved` | `POST /advertisement/listTableApproved`<br>`POST /advertisement/listTableOnProcess`<br>`POST /advertisement/listTableNotApproved` | Tabel khusus pelamar yang sudah Diterima (175), Sedang Diproses (358), atau Ditolak (331) lintas lowongan. |
| **Jadwal & Hasil Interview** | `/interview`, `/interview/create`<br>`/interviewer/{admin_id}`<br>`/interview/daftarConfirm`<br>`/interview/daftarCancel`<br>`/interview/daftarLolos`<br>`/interview/daftarTidaklolos` | `POST /interview/listTable`<br>`POST /Interview/listTableConfirmed`<br>`POST /Interview/listTableCanceled`<br>`POST /interview/listTablePassed`<br>`POST /Interview/listTableFailed`<br>`GET /interview/infoInterview/{id}` | Pembuatan jadwal interview per kode lowongan, pembagian kuota per Interviewer (`admin[]`, `maxKuota[]`), unduh QR kehadiran (`SCHEDULE-{id}.png`), dan pemantauan kandidat Konfirmasi, Batal, Lolos, atau Gagal. |
| **Bank Soal Psikotes** | `/psikotes`<br>`/psikotes/create` | `POST /psikotes/listTable` (406 soal)<br>`GET /psikotes/editPsikotesMateri/{id}`<br>`POST /psikotes/upload-excel` | Kelola soal psikotes (`rankSoal` [`BASIC`, dll.], `typePsikotes` [`Logika`, dll.], pertanyaan CKEditor, 4 pilihan jawaban, kunci jawaban, & impor Excel). |
| **Akses Login Academy** | `/loginapps` | `POST /listloginapps/listTable` (410 data)<br>`POST /Listloginapps/updateApplicant/{id}` | Daftar kandidat lolos interview yang telah memperoleh **NUS Pelamar** (`A1` s.d. `A410`) untuk login ke aplikasi HK Academy. |

---

### C. Kategori: HK ACADEMY (LMS, Training, PKL, & Penempatan)

| Modul / Menu | URL Route | Endpoint DataTables / Action | Fungsi & Field Utama |
|---|---|---|---|
| **Course** | `/course`<br>`/course/create` | `POST /course/listTable`<br>`GET /course/editCourse/{id}`<br>`POST /course/updateCourse` | Induk kurikulum per posisi jabatan (`jobId`, `nameCourse`, `descriptionCourse`, `imageCourse`, `cardCourse`, `certificateCourse`, `statusCourse`). |
| **Module** | `/module`<br>`/module/create` | `POST /module/listTable`<br>`POST /module/updateOrder` | Bab materi di dalam *Course* dengan fitur *drag-and-drop* urutan (`idCourse`, `nameModule`, `descriptionModule`, `imageModule`, `accessModule`, `statusModule`, + *Content Creator*). |
| **Topic** | `/topic`<br>`/topic/create` | `POST /topic/listTable`<br>`POST /topic/updateOrder` | Sub-bab di dalam *Module* (`idModule`, `nameTopic`, `typeTopic`, `accessTopic`, `statusTopic`). |
| **Activity (Material & Quiz)** | `/activity` (atau `/action`)<br>`/activity/material/create`<br>`/activity/quiz/create` | `POST /action/listTable`<br>`POST /action/updateOrder` | Unit pembelajaran terkecil: **Material** (teks bacaan, gambar, video/tautan) dan **Quiz** (soal gambar/audio/teks + pilihan ganda). |
| **Training Online** | `/training/lolosTrainingonline`<br>`/training/gagalTrainingonline` | `POST /training/listTable4`<br>`POST /training/listTable5`<br>`POST /training/updateAlasan`<br>`POST /training/updateAlasanOnlineLolos` | Memantau nilai & kelulusan *e-learning*. Mendukung fitur **Reset Ujian Online**, **Bypass Lolos Online**, dan **Bypass langsung ke Penempatan**. |
| **Training Offline & Bank Soal** | `/training`, `/training/create`<br>`/training/lolosTraining`<br>`/training/gagalTraining`<br>`/training/soal`, `/training/soalCreate` | `POST /training/listTable`<br>`POST /training/listTable6`<br>`POST /training/listTable7`<br>`POST /training/listTable8` | Penjadwalan kelas tatap muka (`codeTraining`, rentang tanggal, jam, lokasi cabang/kustom, kuota Trainer, QR Absensi `TRAINING-{id}.png`), bank soal ujian akhir *Training Offline*, serta daftar peserta lolos/gagal. |
| **PKL (Praktik Kerja Lapangan)** | `/pakelarin` (Waiting List)<br>`/pakelarin/listschedule`<br>`/pakelarin/listtempatpkl`<br>`/pakelarin/listlolospkl`<br>`/pakelarin/listtidaklolospkl`<br>`/pakelarin/listextend`<br>`/pakelarin/listmentor`<br>`/pakelarin/listjob` | `POST /pakelarin/listTable` s.d. `listTable9`<br>`POST /pakelarin/createschedule`<br>`POST /pakelarin/creatementor`<br>`POST /pakelarin/updateSuratPengantar` | Pengelolaan magang lapangan: penentuan lokasi proyek PKL, pembuatan akun **Mentor PKL** (`NUC Login` + password), penjadwalan gelombang PKL, unggah **Surat Pengantar PKL (PDF)**, QR Absensi PKL, daftar tugas/pekerjaan per posisi, hingga rekap nilai (*Score Online*, *Score Offline*, *Score PKL*, *Grade*). |
| **Penempatan & Akun FM** | `/pakelarin/listpenempatan`<br>`/pakelarin/listjadwalpenempatan`<br>`/pakelarin/detailpenempatan/{id}`<br>`/pakelarin/listpenempatanlogin`<br>`/pakelarin/listallpenempatan` | `POST /pakelarin/listTable7` (402 data)<br>`POST /pakelarin/listTable13` (206 jadwal)<br>`POST /pakelarin/listTable19` (Data FM)<br>`POST /pakelarin/updateSuratTugas`<br>`POST /pakelarin/updateByPasstoOpsBySigit` | Tahap akhir sebelum operasional: penjadwalan penempatan ke proyek klien (`PENEMPATAN_{id}`), unggah **Surat Tugas Penempatan**, pembuatan akun **Field Manager (FM)** beserta pemetaan proyeknya (`listDetailProjectFM/{id}`), dan tombol **Bypass to Ops** untuk menjadikan peserta sebagai karyawan aktif. |
| **Banner & Announcement** | `/banner`, `/banner/create`<br>`/announcement`, `/announcement/create` | `POST /banner/listTable`<br>`POST /announcement/listTable` | Manajemen *banner slider* dan pengumuman pada beranda aplikasi mobile. |

---

## 5. Skema Entitas Database Utama (Diekstrak dari JSON Endpoint)

Berikut adalah struktur kolom aktual di database backend yang berhasil dipetakan dari *endpoint* JSON:

1. **`admin_master` (Admin, Supervisor, Interviewer, Trainer)**
   - `admin_master_id`, `admin_master_name`, `admin_master_role`, `admin_master_jabatan`, `admin_master_phone`, `admin_master_email`, `admin_master_password` (bcrypt), `password_show`, `admin_master_image`, `id_cabang`, `admin_master_is_active`, `created_at`, `updated_at`, `created_by`, `updated_by`.
2. **`branch` & `detail_branch` (Kantor Cabang & Lokasi Interview)**
   - `id_branch`, `kode_branch`, `nama_branch`, `address`, `area_kantor_cabang`.
   - `id_detail_branch`, `branch_id`, `address_kode`, `address_cabang`.
3. **`job_position` & `job_criteria` (Posisi & Syarat Jabatan)**
   - `id_job_position`, `code_position`, `nama_position`, `periodic`, `level_position`, `position_image`.
   - Kriteria: `priaCheckbox`, `priaHeight`, `perempuanCheckbox`, `perempuanHeight`, `haveTatoo`, `earPiercing`, `minEducation`, `minAgeUmur`, `maxAgeUmur`, `maritalStatus`, flag dokumen (`certificateEmployment`, `simPhoto`, `sioPhoto`, `certificateCompetency`, `skckPhoto`, `stnkPhoto`).
4. **`applicant` (Data Pelamar — 2.780+ baris)**
   - Identitas: `id_applicant`, `nik_number`, `first_name_applicant`, `last_name_applicant`, `email_applicant`, `phone_applicant`, `password_hash`, `birth_at_applicant`, `birth_date_applicant`, `gender_applicant`, `height_applicant`, `weight_applicant`, `have_tatoo_applicant`, `ear_piercing_applicant`, `marital_status_applicant`, `count_of_children`, `religion_applicant`.
   - Riwayat & Domisili: `last_education_applicant`, `last_job_applicant`, `work_experience_applicant`, `is_experience`, `ever_worked_here`, `nuc_applicant`, `reason_lay_off`, `know_from_who`, `prov_id`, `city_id`, `dis_id`, `subdis_id`, `postal_id`, `address_details_applicant`, `id_penempatan_by_city`, `job_position_applicant`.
   - Berkas Unggahan: `selfie_ktp_applicant`, `photo_education_applicant`, `photo_job_applicant`, `upload_skck_applicant`, `upload_sio_applicant`, `upload_certificate_applicant`, `upload_certificate_vaccine_applicant`, `sertifikat_booster`, `upload_sim_applicant`, `upload_stnk_applicant`, `upload_kk_applicant`, `upload_bpjs`.
   - Autentikasi & Status: `token_applicant`, `isactive_applicant`, `regis_success`, `verification_at`, `activation_code`, `status_blacklist`.
5. **`advertisement` & `user_advertisement` (Lowongan & Lamaran Kandidat)**
   - `id_advertisement`, `advertisement_code`, `id_branch_advert`, `id_detail_cabang`, `id_job_position_advert`, `job_description`, `city_id` (CSV), `pengalaman_lowongan`, `approval_advertisement`, `qrcode`, `start_date`, `end_date`, `advert_image`, `icon_image`.
   - Transaksi Lamaran (`user_advertisement`): `id_user_advertisement`, `id_advertisement`, `id_user_applicant`, `apply_date`, `status_review` (`Approved` / `Not Approved` / `On Process`), `reason_review`, `score_psikotes`, `finished_psikotes_at`, `failed_psikotes_at`, `id_schedule_interview`, `waktu_kehadiran`.
   - Penilaian Interviewer: `data_diri_verification`, `fisik_verification`, `ijazah_verification`, `skck_verification`, `sio_verification`, `pengalaman_ada`, `pengalaman_sesuai`, `grooming`, `intelejensi`, `komunikasi`, `kejujuran`, `hasil`, `review_by_interview`, `update_by_interview`, `user_review_feedback`, `user_interview_feedback`.
6. **`interview_schedule` & `user_interviewer` (Jadwal Interview)**
   - `id_interview`, `kode_interview`, `id_advertisement_code`, `location_cabang`, `date_schedule`, `start_time`, `end_time`, `qrcode_interview`, `confirmation_date`.
   - Kuota: `id_user_interviewer`, `id_interview_schedule`, `id_interviewer_user`, `quota_applicant`.
7. **`login_apps` & `waiting_list_penempatan` (Peserta Academy, PKL & Penempatan)**
   - `id`, `id_applicant`, `id_cabang`, `full_name`, `email`, `phone`, `mother_name`, `blood`, `kk_number`, `nus_pelamar` (mis. `A19`), `job_position`, `level_user`, `token_apps_db`.
   - Tracking Bypass & Approval: `id_approve_online`, `alasan_approve_online`, `id_approve_lolos_online`, `id_approve_bypasspkl`, `id_approve_bypasspenempatan`.
   - Penempatan: `id_waiting_list_penempatan`, `id_penempatan_schedule`, `project_code`, `nuc_user`, `status`, `qrcode_penempatan`, `qrcode_suratpenempatan`, `surat_tugas_penempatan`, `status_persetujuan`, `status_ops`, `id_bypass_to_ops`.
8. **`fieldmanager` (Akun Field Manager Proyek)**
   - `fieldmanager_id`, `fm_name`, `fm_nuc`, `fm_email`, `fm_phone`, `fm_password`, `fm_status`.

---

## 6. Rumus Bisnis & Kontrak Endpoint Langsung (`ops.hk-indonesia.id/hkjobs`)

### A. Autentikasi & Sesi (`adminmaster_session`)
- **Login**: `POST https://ops.hk-indonesia.id/hkjobs/` (`application/x-www-form-urlencoded`: `phone={no_telp}&password={pw}`)
  - Mengembalikan cookie HTTP-Only `adminmaster_session` (masa aktif 7.200 detik / 2 jam) dan me-*redirect* ke `/hkjobs/dashboard`.
- **Deteksi Peran Otomatis dari DOM `/hkjobs/dashboard`**:
  - Nama pengguna diambil dari `.nav-profile-text p` (mis. `DIMAS ALFA PRATAMA`).
  - **Super Admin / Admin**: Memiliki menu `#sidebar` lengkap (`/admin-carefast`, `/organization`, `/advertisement`, `/interview`, `/training`, `/pakelarin`).
  - **Interviewer** (`62002`): Memiliki tautan `/hkjobs/interviewer/{admin_master_id}` (mis. `/interviewer/158`).
  - **Trainer** (`62003`): Hanya memiliki tautan `/hkjobs/training` pada `#sidebar`.
- **Logout**: `GET https://ops.hk-indonesia.id/hkjobs/auth/logout`

### B. Rumus Skor Penilaian Interviewer (`/interview/detailInterview/{id}`)
Saat Interviewer menilai kandidat (`POST /hkjobs/Advertisement/updateAdvertUser`), skor total (`StatusHasil`) dihitung dengan formula:
$$\text{Skor Total} = 25_{\text{(Basis Kejujuran)}} + V_{\text{DataDiri}} + V_{\text{Fisik}} + V_{\text{PengalamanAda}} + V_{\text{PengalamanSesuai}} + V_{\text{Ijazah}} + V_{\text{SKCK}} + V_{\text{SIO}} + R_{\text{Grooming}} + R_{\text{Intelejensi}} + R_{\text{Komunikasi}}$$

| Komponen Verifikasi / Rating | Nilai Opsi | Bobot Poin |
|---|---|---|
| **Basis Kejujuran** | Default tetap | $+25$ |
| **Verifikasi Data Diri** (`data_diri_verification`) | `Sesuai` / `Tidak Sesuai` | $+10$ / $-25$ |
| **Verifikasi Fisik** (`fisik_verification`) | `Sesuai` / `Tidak Sesuai` | $+10$ / $-25$ |
| **Pengalaman Kerja** (`pengalaman_verification`) | `Ada` / `Tidak Ada` | $+5$ / $0$ |
| **Kesesuaian Pengalaman** (`pengalaman_sesuai`) | `Sesuai` / `Tidak Sesuai` | $+5$ / $0$ |
| **Verifikasi Ijazah** (`ijazah_verification`) | `Sesuai` / `Tidak Sesuai` | $+5$ / $0$ |
| **Verifikasi SKCK** (`skck_verification`) | `Sesuai` / `Tidak Sesuai` | $+5$ / $0$ |
| **Verifikasi SIO** (`sio_verification`) | `Sesuai` / `Tidak Sesuai` | $+5$ / $0$ |
| **Rating Grooming** (`groomingRate`) | Skala `2, 4, 6, 8, 10` | $+2$ s.d. $+10$ |
| **Rating Intelejensi** (`intelejenRate`) | Skala `2, 4, 6, 8, 10` | $+2$ s.d. $+10$ |
| **Rating Komunikasi** (`komunikasiRate`) | Skala `2, 4, 6, 8, 10` | $+2$ s.d. $+10$ |

- **Ambang Kelulusan**:
  - $\text{Skor Total} \ge 65 \implies$ `status_pelamar = "Passed"` (Lolos Interview & otomatis mendapat akun HK Academy `NUS`).
  - $\text{Skor Total} \le 64 \implies$ `status_pelamar = "Failed"` (Wajib mengisi `reasonNotApprove`).

### C. Evaluasi Kelulusan Training Offline (`/training/detailTraining/{id}`)
- Daftar peserta per jadwal diambil melalui `POST /hkjobs/training/listTable2/{id_training}`.
- Detail status peserta diambil melalui `GET /hkjobs/training/editStatusPelamar/{id_training_list}` (`id_training_list`, `id_user`).
- **Meloloskan Peserta**: `POST /hkjobs/training/updateLolosTraining` (`id_training_list_lolos`, `id_user_lolos`, `alasanlolos`).
- **Menggagalkan Peserta**: `POST /hkjobs/training/updateTidakLolosTraining` (`id_training_list_tidaklolos`, `id_user_tidaklolos`, `alasanTidaklolos`).

---

## 7. Temuan Keamanan & Teknis Kritis pada Sistem Saat Ini

Saat memetakan server `ops.hk-indonesia.id`, ditemukan beberapa celah keamanan serius yang **wajib diperhatikan**:

> [!CAUTION]
> **1. Directory Listing Terbuka pada `/assetshkjobs/`**
> URL `https://ops.hk-indonesia.id/assetshkjobs/` mengizinkan *Apache Directory Listing* tanpa autentikasi. Seluruh folder dokumen pribadi pelamar (`ktp/`, `kk/`, `sim/`, `sio/`, `skck/`, `document/`, `qrcode/`) dapat dijelajahi publik. Matikan segera dengan `Options -Indexes` pada konfigurasi Apache/ `.htaccess`.

> [!WARNING]
> **2. Penyimpanan Password Plaintext (`password_show` & `fm_password`)**
> Endpoint JSON seperti `/admin/editAdminMaster`, `/applicant/editApplicant`, dan `/pakelarin/editPenempatan` mengembalikan kolom `password_show` (password asli dalam teks biasa) ke klien.

> [!IMPORTANT]
> **3. Protokol DataTables & Hybrid HTML-in-JSON**
> Endpoint daftar (`*/listTable*`) mengembalikan JSON DataTables di mana beberapa sel berisi potongan HTML (`<a href="...">`, `<label class="badge">`, `onclick="editAdminMaster(158)"`). Aplikasi Flutter mem-parsing respons ini di lapisan *data boundary* (menggunakan `Isolate.run` untuk payload besar) menjadi model *immutable* bertipe kuat sebelum masuk ke UI.

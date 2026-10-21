import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/utils/form_html_parser.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/widgets/hk_form_widgets.dart' show QuotaEntry;

typedef FormSelects = Map<String, List<SelectOption>>;

@immutable
class LocationInfo {
  const LocationInfo({required this.area, required this.address});

  final String area;
  final String address;
}

@immutable
class AdminDraft {
  const AdminDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirm,
    required this.role,
    required this.branchId,
    required this.position,
    required this.isActive,
    this.photo,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirm;
  final String role;
  final String branchId;
  final String position;
  final bool isActive;
  final PickedImage? photo;
}

@immutable
class VacancyDraft {
  const VacancyDraft({
    required this.branchId,
    required this.subBranchId,
    required this.code,
    required this.positionId,
    required this.descriptionHtml,
    required this.cityIds,
    required this.experience,
    required this.startDate,
    required this.endDate,
    this.banner,
    this.icon,
    this.vacancyId,
  });

  final String? vacancyId;
  final String branchId;
  final String subBranchId;
  final String code;
  final PickedImage? banner;
  final PickedImage? icon;
  final String positionId;
  final String descriptionHtml;
  final List<String> cityIds;
  final String experience;
  final String startDate;
  final String endDate;
}

@immutable
class InterviewDraft {
  const InterviewDraft({
    required this.vacancyId,
    required this.locationId,
    required this.area,
    required this.address,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.quotas,
  });

  final String vacancyId;
  final String locationId;
  final String area;
  final String address;
  final String date;
  final String timeStart;
  final String timeEnd;
  final List<QuotaEntry> quotas;
}

@immutable
class TrainingDraft {
  const TrainingDraft({
    required this.code,
    required this.branchId,
    required this.locationId,
    required this.area,
    required this.address,
    required this.customAddress,
    required this.startDate,
    required this.endDate,
    required this.timeStart,
    required this.timeEnd,
    required this.rank,
    required this.positionId,
    required this.quotas,
  });

  final String code;
  final String branchId;
  final String locationId;
  final String area;
  final String address;
  final String? customAddress;
  final String startDate;
  final String endDate;
  final String timeStart;
  final String timeEnd;
  final String rank;
  final String positionId;
  final List<QuotaEntry> quotas;
}

@immutable
class PlacementDraft {
  const PlacementDraft({
    required this.projectId,
    required this.lokasiProject,
    required this.positionId,
    required this.quota,
    required this.tanggal,
    required this.timeStart,
    required this.timeEnd,
  });

  final String projectId;
  final String lokasiProject;
  final String positionId;
  final String quota;
  final String tanggal;
  final String timeStart;
  final String timeEnd;

  Map<String, String> toFormDataMap() => <String, String>{
    'projectId': projectId,
    'lokasiProject': lokasiProject.trim(),
    'positionId': positionId,
    'kuotaApplicant': quota.trim(),
    'tanggal': tanggal,
    'timeStart': timeStart,
    'timeEnd': timeEnd,
  };
}

final managementRepositoryProvider = Provider<ManagementRepository>((ref) {
  return ManagementRepository(apiClient: ref.watch(hkJobsApiClientProvider));
});

/// Pilihan `<select>` dari halaman create (server-rendered), di-cache per path
/// selama layar form hidup.
final formSelectsProvider = FutureProvider.autoDispose
    .family<FormSelects, String>((ref, path) async {
      final repo = ref.watch(managementRepositoryProvider);
      final result = await repo.loadSelects(path);
      switch (result) {
        case Success<FormSelects>(:final data):
          return data;
        case Failure<FormSelects>(:final error):
          throw error;
      }
    });

class ManagementRepository {
  const ManagementRepository({required HkJobsApiClient apiClient})
    : _apiClient = apiClient;

  final HkJobsApiClient _apiClient;

  Future<Result<FormSelects>> loadSelects(String createPath) async {
    final raw = await _apiClient.getRaw(createPath);
    switch (raw) {
      case Failure<String>(:final error):
        return Failure<FormSelects>(error);
      case Success<String>(:final data):
        try {
          final parsed = await Isolate.run(
            () => FormHtmlParser.parseSelects(data),
          );
          return Success<FormSelects>(parsed);
        } on Object {
          return const Failure<FormSelects>(ParseFailure());
        }
    }
  }

  Future<Result<List<SelectOption>>> loadLocations({
    required String endpoint,
    required String parentId,
    bool usePost = false,
  }) async {
    final res = await _apiClient.getJson(
      endpoint,
      query: <String, Object?>{'id': parentId},
      usePost: usePost,
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<List<SelectOption>>(error);
      case Success<Object?>(:final data):
        if (data is! List<Object?>) {
          return const Success<List<SelectOption>>(<SelectOption>[]);
        }
        final options = <SelectOption>[];
        for (final item in data) {
          if (item is Map) {
            final id = item['id_detail_branch']?.toString() ?? '';
            final label = (item['address_kode']?.toString() ?? '').trim();
            if (id.isNotEmpty) {
              options.add(SelectOption(value: id, label: label));
            }
          }
        }
        return Success<List<SelectOption>>(options);
    }
  }

  Future<Result<LocationInfo>> loadLocationInfo({
    required String endpoint,
    required String locationId,
  }) async {
    final res = await _apiClient.getJson(
      endpoint,
      query: <String, Object?>{'id': locationId},
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<LocationInfo>(error);
      case Success<Object?>(:final data):
        if (data is! Map) return const Failure<LocationInfo>(ParseFailure());
        return Success<LocationInfo>(
          LocationInfo(
            area: (data['address_kode']?.toString() ?? '').trim(),
            address: (data['address_cabang']?.toString() ?? '').trim(),
          ),
        );
    }
  }

  Future<Result<String>> loadVacancyCodePrefix(String subBranchId) async {
    final res = await _apiClient.getJson(
      ApiEndpoints.vacancyCodePrefix,
      query: <String, Object?>{'id': subBranchId},
      usePost: true,
    );
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<String>(error);
      case Success<Object?>(:final data):
        if (data is! Map) return const Failure<String>(ParseFailure());
        final kode = data['kode_branch']?.toString() ?? '';
        return Success<String>('${kode}_');
    }
  }

  Future<Result<Map<String, Object?>>> loadVacancyDetail(String id) {
    return _apiClient.getJsonMap(ApiEndpoints.advertisementDetailJson(id));
  }

  Future<Result<void>> createAdmin(AdminDraft d) {
    return _apiClient.submitForm(ApiEndpoints.adminCreate, () {
      final map = <String, Object>{
        'nameAdminMaster': d.name.trim(),
        'emailAdminMaster': d.email.trim(),
        'phoneAdminMaster': d.phone.trim(),
        'passwordAdminMaster1': d.password,
        'passwordAdminMaster2': d.passwordConfirm,
        'roleAdmin': d.role,
        'cabangid': d.branchId,
        'jabatanAdmin': d.position.trim(),
        'statusAdminMaster': d.isActive ? '1' : '0',
      };
      if (d.photo != null) map['imageUser'] = d.photo!.toMultipart();
      return FormData.fromMap(map);
    });
  }

  Future<Result<void>> createVacancy(VacancyDraft d) {
    return _apiClient.submitForm(ApiEndpoints.vacancyCreate, () {
      final map = <String, Object>{
        'branchId': d.branchId,
        'kantorCabangPembantu': d.subBranchId,
        'codeAdvertisement': d.code.trim(),
        'jobId': d.positionId,
        'descriptionAdvert': d.descriptionHtml,
        'selectProvince[]': d.cityIds,
        'optionPengalaman': d.experience,
        'dateStart': d.startDate,
        'dateEnd': d.endDate,
      };
      if (d.banner != null) map['imageAdvert'] = d.banner!.toMultipart();
      if (d.icon != null) map['iconAdvert'] = d.icon!.toMultipart();
      return FormData.fromMap(map);
    });
  }

  Future<Result<void>> updateVacancy(VacancyDraft d) async {
    final res = await _apiClient.postFormJson(ApiEndpoints.vacancyUpdate, () {
      return FormData.fromMap(<String, Object>{
        'id_advert': d.vacancyId ?? '',
        'codeAdvertisement': d.code.trim(),
        'branchId': d.branchId,
        'jobId': d.positionId,
        'descriptionAdvert': d.descriptionHtml,
        'selectProvince[]': d.cityIds,
        'optionPengalaman': d.experience,
        'dateStart': d.startDate,
        'dateEnd': d.endDate,
      });
    });
    switch (res) {
      case Failure<Object?>(:final error):
        return Failure<void>(error);
      case Success<Object?>():
        return const Success<void>(null);
    }
  }

  Future<Result<void>> createInterview(InterviewDraft d) {
    return _apiClient.submitForm(ApiEndpoints.interviewCreate, () {
      return FormData.fromMap(<String, Object>{
        'advertId': d.vacancyId,
        'lokasiDetailCabang': d.locationId,
        'areaCabang': d.area,
        'lokasiCabang': d.address,
        'tanggal': d.date,
        'timeStart': d.timeStart,
        'timeEnd': d.timeEnd,
        'maxKuota[]': d.quotas.map((e) => e.quota).toList(),
        'admin[]': d.quotas.map((e) => e.personId).toList(),
      });
    });
  }

  Future<Result<void>> createTraining(TrainingDraft d) {
    return _apiClient.submitForm(ApiEndpoints.trainingCreate, () {
      final map = <String, Object>{
        'codeTraining': d.code.trim(),
        'advertId': d.branchId,
        'lokasiDetailCabang': d.locationId,
        'areaCabang': d.area,
        'lokasiCabang': d.address,
        'jadwalTraining': d.startDate,
        'jadwalTraining2': d.endDate,
        'timeStart': d.timeStart,
        'timeEnd': d.timeEnd,
        'rankCourse': d.rank,
        'jobId': d.positionId,
        'maxKuota[]': d.quotas.map((e) => e.quota).toList(),
        'admin[]': d.quotas.map((e) => e.personId).toList(),
      };
      final custom = d.customAddress;
      if (custom != null && custom.trim().isNotEmpty) {
        map['checkboxLokasi'] = 'on';
        map['alamatInterview'] = custom.trim();
      }
      return FormData.fromMap(map);
    });
  }

  Future<Result<void>> createPlacement(PlacementDraft d) {
    return _apiClient.submitForm(ApiEndpoints.placementScheduleCreate, () {
      return FormData.fromMap(d.toFormDataMap());
    });
  }
}

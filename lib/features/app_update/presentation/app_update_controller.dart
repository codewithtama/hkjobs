import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/app_update_repository.dart';
import '../domain/update_info.dart';

@immutable
class AppUpdateState {
  const AppUpdateState({
    this.info,
    this.isChecking = false,
    this.hasDismissed = false,
    this.errorMessage,
  });

  final UpdateInfo? info;
  final bool isChecking;
  final bool hasDismissed;
  final String? errorMessage;

  AppUpdateState copyWith({
    UpdateInfo? info,
    bool? isChecking,
    bool? hasDismissed,
    String? errorMessage,
  }) {
    return AppUpdateState(
      info: info ?? this.info,
      isChecking: isChecking ?? this.isChecking,
      hasDismissed: hasDismissed ?? this.hasDismissed,
      errorMessage: errorMessage,
    );
  }
}

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>((ref) {
  final repo = ref.watch(appUpdateRepositoryProvider);
  return AppUpdateController(repo);
});

class AppUpdateController extends StateNotifier<AppUpdateState> {
  AppUpdateController(this._repository) : super(const AppUpdateState());

  final AppUpdateRepository _repository;

  Future<UpdateInfo?> checkForUpdates({bool isManual = false}) async {
    state = state.copyWith(isChecking: true, errorMessage: null);
    final res = await _repository.checkForUpdate();
    switch (res) {
      case Success<UpdateInfo>(:final data):
        state = state.copyWith(
          info: data,
          isChecking: false,
          hasDismissed: isManual ? false : state.hasDismissed,
        );
        return data;
      case Failure<UpdateInfo>(:final error):
        state = state.copyWith(
          isChecking: false,
          errorMessage: error.message,
        );
        return null;
    }
  }

  void dismissUpdate() {
    state = state.copyWith(hasDismissed: true);
  }

  void resetDismissed() {
    state = state.copyWith(hasDismissed: false);
  }
}

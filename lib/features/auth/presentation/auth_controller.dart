import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/auth_repository.dart';
import '../domain/admin_session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AdminSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AdminSession?> {
  @override
  Future<AdminSession?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.restoreSession();
  }

  Future<AppFailure?> signIn({
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading<AdminSession?>();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(phone: phone, password: password);
    switch (result) {
      case Success<AdminSession>(:final data):
        state = AsyncData<AdminSession?>(data);
        return null;
      case Failure<AdminSession>(:final error):
        state = const AsyncData<AdminSession?>(null);
        return error;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AdminSession?>();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData<AdminSession?>(null);
  }
}

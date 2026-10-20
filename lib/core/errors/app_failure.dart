sealed class AppFailure {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'Tidak dapat terhubung ke server ops.hk-indonesia.id. Periksa koneksi internet Anda.',
  ]) : super(code: 'NETWORK_ERROR');
}

final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure([
    super.message = 'Sesi login telah berakhir. Silakan masuk kembali.',
  ]) : super(code: 'SESSION_EXPIRED');
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message) : super(code: 'VALIDATION_ERROR');
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code = 'SERVER_ERROR'});
}

final class ParseFailure extends AppFailure {
  const ParseFailure([
    super.message = 'Format respons dari server tidak dapat diproses.',
  ]) : super(code: 'PARSE_ERROR');
}

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

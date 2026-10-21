import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../errors/app_failure.dart';
import '../storage/secure_session_storage.dart';
import '../utils/form_html_parser.dart';
import '../utils/html_cell_parser.dart';

final hkJobsApiClientProvider = Provider<HkJobsApiClient>((ref) {
  final storage = ref.watch(secureSessionStorageProvider);
  return HkJobsApiClient(storage: storage);
});

class HkJobsApiClient {
  HkJobsApiClient({required SecureSessionStorage storage})
    : _storage = storage,
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  final SecureSessionStorage _storage;
  final Dio _dio;
  String? _activeCookie;
  Completer<bool>? _refreshCompleter;

  void setMemoryCookie(String cookieHeader) {
    _activeCookie = cookieHeader;
  }

  void clearMemoryCookie() {
    _activeCookie = null;
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_activeCookie == null || _activeCookie!.isEmpty) {
      final stored = await _storage.readSession();
      if (stored != null && stored.cookieHeader.isNotEmpty) {
        _activeCookie = stored.cookieHeader;
      }
    }
    if (_activeCookie != null &&
        _activeCookie!.isNotEmpty &&
        !options.headers.containsKey('Cookie')) {
      options.headers['Cookie'] = _activeCookie;
    }
    handler.next(options);
  }

  Future<void> _onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) async {
    final extracted = extractSessionCookie(response.headers);
    if (extracted != null && extracted.isNotEmpty) {
      _activeCookie = extracted;
      await _storage.updateCookie(extracted);
    }
    handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final isIdempotent =
        req.method == 'GET' ||
        req.path.contains('listTable') ||
        req.path.contains('dataDashboardFilter');
    final retryCount = (req.extra['retry_count'] as int?) ?? 0;

    if (isIdempotent &&
        retryCount < 1 &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError)) {
      req.extra['retry_count'] = retryCount + 1;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try {
        final retryResp = await _dio.fetch<Object?>(req);
        handler.resolve(retryResp);
        return;
      } on DioException catch (retryErr) {
        handler.next(retryErr);
        return;
      }
    }

    handler.next(err);
  }

  static String? extractSessionCookie(Headers headers) {
    final cookies = headers['set-cookie'];
    if (cookies == null || cookies.isEmpty) return null;
    for (final raw in cookies.reversed) {
      final match = RegExp(r'(adminmaster_session=[^;]+)').firstMatch(raw);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  bool _isRedirectedToLogin(Response<Object?> response) {
    if (response.statusCode == 302 || response.statusCode == 303) {
      final location = response.headers.value('location') ?? '';
      if (location == ApiEndpoints.baseUrl ||
          location.endsWith('/hkjobs') ||
          location.endsWith('/hkjobs/')) {
        return true;
      }
    }
    final body = response.data?.toString() ?? '';
    return body.contains('<title>Login Admin - Hygiene Kleen</title>');
  }

  /// Single in-flight session refresh when the 2-hour CodeIgniter cookie expires.
  Future<bool> _ensureValidSession() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final stored = await _storage.readSession();
      if (stored == null) {
        completer.complete(false);
        return false;
      }

      final loginResp = await _dio.post<String>(
        ApiEndpoints.login,
        data: <String, String>{
          'phone': stored.phone,
          'password': stored.password,
        },
        options: Options(headers: <String, Object?>{}, followRedirects: false),
      );

      final newCookie = extractSessionCookie(loginResp.headers);
      if (newCookie != null && newCookie.isNotEmpty) {
        _activeCookie = newCookie;
        await _storage.updateCookie(newCookie);
        completer.complete(true);
        return true;
      }
      completer.complete(false);
      return false;
    } on DioException {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Result<String>> getRaw(String path) async {
    try {
      var response = await _dio.get<String>(path);
      if (_isRedirectedToLogin(response)) {
        final refreshed = await _ensureValidSession();
        if (!refreshed) {
          return const Failure<String>(SessionExpiredFailure());
        }
        response = await _dio.get<String>(path);
      }
      return Success<String>(response.data ?? '');
    } on DioException catch (e) {
      return Failure<String>(_mapDioException(e));
    }
  }

  Future<Result<Map<String, Object?>>> getJsonMap(String path) async {
    final rawResult = await getRaw(path);
    switch (rawResult) {
      case Failure<String>(:final error):
        return Failure<Map<String, Object?>>(error);
      case Success<String>(:final data):
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, Object?>) {
            return Success<Map<String, Object?>>(decoded);
          }
          if (decoded is Map) {
            return Success<Map<String, Object?>>(
              decoded.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return const Failure<Map<String, Object?>>(ParseFailure());
        } on FormatException {
          return const Failure<Map<String, Object?>>(ParseFailure());
        }
    }
  }

  Future<Result<String>> postFormRaw(
    String path,
    Map<String, Object?> formFields,
  ) async {
    try {
      final formData = FormData.fromMap(formFields);
      var response = await _dio.post<String>(path, data: formData);
      if (_isRedirectedToLogin(response)) {
        final refreshed = await _ensureValidSession();
        if (!refreshed) {
          return const Failure<String>(SessionExpiredFailure());
        }
        response = await _dio.post<String>(
          path,
          data: FormData.fromMap(formFields),
        );
      }
      return Success<String>(response.data ?? '');
    } on DioException catch (e) {
      return Failure<String>(_mapDioException(e));
    }
  }

  Future<Result<ParsedDataTableResult>> fetchDataTable({
    required String endpoint,
    int start = 0,
    int length = 30,
    String searchQuery = '',
  }) async {
    final payload = <String, Object?>{
      'draw': '1',
      'start': start.toString(),
      'length': length.toString(),
      'search[value]': searchQuery.trim(),
      'search[regex]': 'false',
      'order[0][column]': '0',
      'order[0][dir]': 'asc',
    };

    final rawResult = await postFormRaw(endpoint, payload);
    switch (rawResult) {
      case Failure<String>(:final error):
        return Failure<ParsedDataTableResult>(error);
      case Success<String>(:final data):
        try {
          final parsed = await Isolate.run(
            () => HtmlCellParser.parseDataTablePayload(data),
          );
          return Success<ParsedDataTableResult>(parsed);
        } on Object {
          return const Failure<ParsedDataTableResult>(ParseFailure());
        }
    }
  }

  /// Mengirim form CodeIgniter (multipart). Sukses = redirect 3xx; status 200
  /// berarti halaman form dirender ulang berisi pesan validasi.
  Future<Result<void>> submitForm(
    String path,
    FormData Function() buildForm,
  ) async {
    try {
      var response = await _dio.post<String>(path, data: buildForm());
      if (_isRedirectedToLogin(response)) {
        final refreshed = await _ensureValidSession();
        if (!refreshed) {
          return const Failure<void>(SessionExpiredFailure());
        }
        response = await _dio.post<String>(path, data: buildForm());
      }
      final status = response.statusCode ?? 0;
      if (status >= 300 && status < 400) {
        return const Success<void>(null);
      }
      final body = response.data ?? '';
      final errors = await Isolate.run(
        () => FormHtmlParser.parseValidationErrors(body),
      );
      if (errors.isNotEmpty) {
        return Failure<void>(ValidationFailure(errors.join('\n')));
      }
      return const Failure<void>(
        ServerFailure(
          'Server tidak mengonfirmasi penyimpanan. Periksa daftar data sebelum mengulang.',
        ),
      );
    } on DioException catch (e) {
      return Failure<void>(_mapDioException(e));
    }
  }

  /// Mengirim POST AJAX berbalas JSON (mis. `updateAdminMaster`).
  Future<Result<Object?>> postFormJson(
    String path,
    FormData Function() buildForm,
  ) async {
    try {
      var response = await _dio.post<String>(path, data: buildForm());
      if (_isRedirectedToLogin(response)) {
        final refreshed = await _ensureValidSession();
        if (!refreshed) {
          return const Failure<Object?>(SessionExpiredFailure());
        }
        response = await _dio.post<String>(path, data: buildForm());
      }
      final body = response.data ?? '';
      try {
        return Success<Object?>(jsonDecode(body));
      } on FormatException {
        return const Failure<Object?>(ParseFailure());
      }
    } on DioException catch (e) {
      return Failure<Object?>(_mapDioException(e));
    }
  }

  Future<Result<Object?>> getJson(
    String path, {
    Map<String, Object?>? query,
    bool usePost = false,
  }) async {
    try {
      Response<String> response = usePost
          ? await _dio.post<String>(path, data: query)
          : await _dio.get<String>(path, queryParameters: query);
      if (_isRedirectedToLogin(response)) {
        final refreshed = await _ensureValidSession();
        if (!refreshed) {
          return const Failure<Object?>(SessionExpiredFailure());
        }
        response = usePost
            ? await _dio.post<String>(path, data: query)
            : await _dio.get<String>(path, queryParameters: query);
      }
      try {
        return Success<Object?>(jsonDecode(response.data ?? 'null'));
      } on FormatException {
        return const Failure<Object?>(ParseFailure());
      }
    } on DioException catch (e) {
      return Failure<Object?>(_mapDioException(e));
    }
  }

  Future<Response<String>> postLoginRequest({
    required String phone,
    required String password,
  }) {
    return _dio.post<String>(
      ApiEndpoints.login,
      data: <String, String>{'phone': phone, 'password': password},
      options: Options(headers: <String, Object?>{}, followRedirects: false),
    );
  }

  AppFailure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const SessionExpiredFailure();
    }
    return ServerFailure(
      'Permintaan gagal diproses server (HTTP ${statusCode ?? 'Unknown'}).',
    );
  }
}

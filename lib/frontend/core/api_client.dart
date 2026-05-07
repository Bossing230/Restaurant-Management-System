import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  ApiClient(this._storage, this._logger) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.addAll([
      _AuthInterceptor(_storage, dio),
      _LoggingInterceptor(_logger),
    ]);
  }
}

// ── JWT attach + auto-refresh on 401 ─────────────────────────
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refresh = await _storage.read(key: AppConstants.refreshKey);
        final res = await _dio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refresh},
        );
        final newToken = res.data['data']['token'] as String;
        await _storage.write(key: AppConstants.tokenKey, value: newToken);
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        handler.resolve(await _dio.fetch(err.requestOptions));
        return;
      } catch (_) {
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

// ── Request / response logger ─────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  final Logger _log;
  _LoggingInterceptor(this._log);

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    _log.d('[→] ${o.method} ${o.path}');
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    _log.d('[←] ${r.statusCode} ${r.requestOptions.path}');
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    _log.e('[✗] ${e.message}', error: e);
    h.next(e);
  }
}
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Wraps [Dio], unwraps the backend's `{ success, message, data, meta }`
/// envelope, and converts every failure into an [ApiException]. Feature
/// repositories talk to this, never to Dio directly.
class ApiClient {
  ApiClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Bare client (no auth interceptor) used internally for the refresh
    // call itself, so it never recurses back into this interceptor.
    final Dio refreshDio = Dio(_dio.options);

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage: _secureStorage, refreshDio: refreshDio),
      PrettyDioLogger(
        requestBody: true,
        responseBody: true,
        compact: true,
        maxWidth: 100,
      ),
    ]);
  }

  final SecureStorage _secureStorage;
  late final Dio _dio;

  /// Returns the unwrapped `data` payload (a Map, List, or primitive).
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _request(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  /// Returns the full envelope so callers needing `meta` (pagination) can read it.
  Future<Map<String, dynamic>> getEnvelope(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _requestEnvelope(
        () => _dio.get<dynamic>(path, queryParameters: queryParameters),
      );

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
  }) =>
      _request(
        () => _dio.post<dynamic>(
          path,
          data: data,
          options: headers != null ? Options(headers: headers) : null,
        ),
      );

  Future<dynamic> patch(String path, {Object? data}) =>
      _request(() => _dio.patch<dynamic>(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _request(() => _dio.delete<dynamic>(path, data: data));

  /// Downloads a binary response (e.g. invoice PDF) as raw bytes.
  Future<List<int>> download(String path) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    final Map<String, dynamic> envelope = await _requestEnvelope(call);
    return envelope['data'];
  }

  Future<Map<String, dynamic>> _requestEnvelope(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final Response<dynamic> response = await call();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return ApiException.network();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException.timeout();
    }
    return ApiException.fromResponseData(
      e.response?.data,
      statusCode: e.response?.statusCode,
    );
  }
}

import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'session_events.dart';

/// Attaches the access token to every request and, on a 401 with code
/// `TOKEN_EXPIRED`, performs a single in-flight refresh (concurrent 401s
/// share the same refresh call) before retrying the original request once.
/// A refresh failure (revoked/expired refresh token) clears local tokens
/// and broadcasts [SessionEvents.onUnauthorized] for the app shell to react to.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required Dio refreshDio,
  })  : _secureStorage = secureStorage,
        _refreshDio = refreshDio;

  final SecureStorage _secureStorage;
  final Dio _refreshDio;

  Future<String?>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _secureStorage.accessToken;
    if (token != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final Response<dynamic>? response = err.response;
    final bool isExpired = response?.statusCode == 401 &&
        (response?.data is Map &&
            (response!.data as Map)['code'] == 'TOKEN_EXPIRED');
    final bool alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isExpired || alreadyRetried) {
      handler.next(err);
      return;
    }

    final String? newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      handler.next(err);
      return;
    }

    try {
      final RequestOptions retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra['retried'] = true;
      final Response<dynamic> retryResponse = await _refreshDio.fetch<dynamic>(
        retryOptions,
      );
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    // Single-flight: concurrent 401s await the same refresh call rather
    // than each racing to rotate the refresh token (rotation invalidates
    // the previous token, so a second concurrent refresh would fail).
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _performRefresh() async {
    final String? refreshToken = await _secureStorage.refreshToken;
    if (refreshToken == null) {
      SessionEvents.notifyUnauthorized();
      return null;
    }

    try {
      final Response<dynamic> response = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final Map<String, dynamic> data =
          (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final String accessToken = data['accessToken'] as String;
      final String newRefreshToken = data['refreshToken'] as String;

      await _secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } on DioException {
      await _secureStorage.clearTokens();
      SessionEvents.notifyUnauthorized();
      return null;
    }
  }
}

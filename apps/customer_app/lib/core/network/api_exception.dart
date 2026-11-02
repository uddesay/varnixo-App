/// A field-level validation error, mirrors the backend's
/// `{ field, message }` shape inside `errors[]`.
class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) => ApiFieldError(
        field: json['field'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String field;
  final String message;
}

/// Thrown by [ApiClient] for any non-2xx response or transport failure.
/// Carries the backend's machine-readable `code` so callers can branch on
/// specific conditions (e.g. `TOKEN_EXPIRED`, `RATE_LIMITED`) instead of
/// parsing message strings.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors = const [],
  });

  factory ApiException.fromResponseData(
    dynamic data, {
    int? statusCode,
  }) {
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message'] as String? ?? 'Something went wrong',
        statusCode: statusCode,
        code: data['code'] as String?,
        errors: (data['errors'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ApiFieldError.fromJson)
            .toList(),
      );
    }
    return ApiException(
      message: 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }

  factory ApiException.network() => const ApiException(
        message: 'No internet connection. Please check your network.',
        code: 'NETWORK_ERROR',
      );

  factory ApiException.timeout() => const ApiException(
        message: 'The request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  final String message;
  final int? statusCode;
  final String? code;
  final List<ApiFieldError> errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => code == 'VALIDATION_ERROR';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

import '../../../core/network/api_client.dart';
import '../domain/user.dart';

/// Result of any endpoint that issues a session (login, register, OTP
/// verify, OAuth) — token persistence is handled by [AuthController], not
/// here, keeping this layer a pure API mapper.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> tokens =
        json['tokens'] as Map<String, dynamic>;
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }

  final User user;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
}

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthResult> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    final data = await _client.post('/auth/register', data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
      'fullName': fullName,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    },);
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _client.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    },);
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> requestOtp(String identifier) => _client.post(
        '/auth/otp/request',
        data: {'identifier': identifier},
      );

  Future<AuthResult> verifyOtp({
    required String identifier,
    required String code,
    String? fullName,
  }) async {
    final data = await _client.post('/auth/otp/verify', data: {
      'identifier': identifier,
      'code': code,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
    },);
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResult> googleSignIn(String idToken) async {
    final data = await _client.post(
      '/auth/oauth/google',
      data: {'idToken': idToken},
    );
    return AuthResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String identifier) => _client.post(
        '/auth/password/forgot',
        data: {'identifier': identifier},
      );

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) =>
      _client.post('/auth/password/reset', data: {
        'identifier': identifier,
        'code': code,
        'newPassword': newPassword,
      },);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _client.post('/auth/password/change', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },);

  Future<void> logout(String refreshToken) => _client.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );

  Future<void> logoutAll() => _client.post('/auth/logout-all');

  Future<User> me() async {
    final data = await _client.get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }
}

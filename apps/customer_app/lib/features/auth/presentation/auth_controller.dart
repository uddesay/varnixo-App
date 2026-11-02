import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_events.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(AuthController.new);

/// Owns the app-wide session: bootstraps from stored tokens on launch,
/// drives every auth flow, and reacts to forced-logout events raised by the
/// network layer (refresh-token expiry/revocation).
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _unauthorizedSub = SessionEvents.onUnauthorized.listen((_) => _forceLogout());
    unawaited(bootstrap());
  }

  final Ref _ref;
  late final StreamSubscription<void> _unauthorizedSub;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    final String? accessToken =
        await _ref.read(secureStorageProvider).accessToken;
    if (accessToken == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repository.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      unawaited(_ref.read(socketClientProvider).connect());
    } on ApiException {
      // Access token invalid and silent refresh (handled by the network
      // layer) also failed — fall back to signed-out.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> _persistAndSetSession(AuthResult result) async {
    await _ref.read(secureStorageProvider).saveTokens(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: result.user,
      isLoading: false,
      clearError: true,
    );
    unawaited(_ref.read(socketClientProvider).connect());
    return true;
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await action();
      return _persistAndSetSession(result);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> login({required String identifier, required String password}) =>
      _run(() => _repository.login(identifier: identifier, password: password));

  Future<bool> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
    String? referralCode,
  }) =>
      _run(() => _repository.register(
            email: email,
            phone: phone,
            password: password,
            fullName: fullName,
            referralCode: referralCode,
          ),);

  Future<bool> requestOtp(String identifier) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.requestOtp(identifier);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String identifier,
    required String code,
    String? fullName,
  }) =>
      _run(() => _repository.verifyOtp(
            identifier: identifier,
            code: code,
            fullName: fullName,
          ),);

  Future<bool> googleSignIn(String idToken) =>
      _run(() => _repository.googleSignIn(idToken));

  Future<bool> forgotPassword(String identifier) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.forgotPassword(identifier);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.resetPassword(
        identifier: identifier,
        code: code,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    final String? refreshToken =
        await _ref.read(secureStorageProvider).refreshToken;
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken);
      } on ApiException {
        // Best-effort — clear local session regardless of server response.
      }
    }
    await _forceLogout();
  }

  Future<void> _forceLogout() async {
    await _ref.read(secureStorageProvider).clearTokens();
    _ref.read(socketClientProvider).disconnect();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    unawaited(_unauthorizedSub.cancel());
    super.dispose();
  }
}

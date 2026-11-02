import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';

/// Bridges Riverpod's [AuthController] to go_router's [Listenable]-based
/// `refreshListenable`, so navigation reacts immediately to login/logout
/// without the UI having to manually trigger a redirect.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.status != next.status) notifyListeners();
      },
    );
  }

  final Ref _ref;

  AuthStatus get status => _ref.read(authControllerProvider).status;
}

final Provider<RouterNotifier> routerNotifierProvider = Provider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

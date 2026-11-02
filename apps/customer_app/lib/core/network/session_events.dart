import 'dart:async';

/// Decouples the network layer from app state management: the auth
/// interceptor cannot depend on Riverpod providers (that would create a
/// dependency cycle with the Dio provider it's attached to), so it emits
/// here instead. The app root listens and drives the session provider +
/// router redirect.
abstract final class SessionEvents {
  static final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();

  static Stream<void> get onUnauthorized => _unauthorizedController.stream;

  static void notifyUnauthorized() => _unauthorizedController.add(null);
}

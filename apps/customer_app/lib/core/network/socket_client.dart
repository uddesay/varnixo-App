import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Thin wrapper around a singleton Socket.IO connection to the backend's
/// realtime gateway (`backend/src/sockets/index.js`). The server joins every
/// authenticated connection to a `user:{id}` room automatically, so no
/// client-side room management is needed — we just forward the events we
/// care about into broadcast streams that feature controllers subscribe to.
///
/// Streams (rather than raw `socket.on` callbacks) mean UI code never has to
/// know whether the socket is connected yet: subscribing before `connect()`
/// resolves is safe, events simply start flowing once the handshake lands.
class SocketClient {
  SocketClient({required SecureStorage secureStorage}) : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;
  sio.Socket? _socket;

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _supportMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Fires on every `notification` push (order/return/payment/etc. updates).
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  /// Fires on every `support:message` push (a new chat reply on any of the
  /// current user's tickets).
  Stream<Map<String, dynamic>> get onSupportMessage => _supportMessageController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Idempotent — safe to call from multiple places (auth bootstrap, login,
  /// app resume) without opening duplicate connections.
  Future<void> connect() async {
    if (_socket != null) return;
    final String? token = await _secureStorage.accessToken;
    if (token == null) return;

    _socket = sio.io(
      Env.socketUrl,
      sio.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    )
      ..on('notification', (data) => _emit(_notificationController, data))
      ..on('support:message', (data) => _emit(_supportMessageController, data))
      ..connect();
  }

  void _emit(StreamController<Map<String, dynamic>> controller, dynamic data) {
    if (data is Map) controller.add(Map<String, dynamic>.from(data));
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}

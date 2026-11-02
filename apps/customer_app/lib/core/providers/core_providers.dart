import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/socket_client.dart';
import '../storage/secure_storage.dart';

final Provider<SecureStorage> secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(),
);

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(secureStorage: ref.watch(secureStorageProvider)),
);

final Provider<SocketClient> socketClientProvider = Provider<SocketClient>(
  (ref) => SocketClient(secureStorage: ref.watch(secureStorageProvider)),
);

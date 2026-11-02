import '../../../core/network/api_client.dart';
import '../domain/notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final ApiClient _client;

  /// The list endpoint nests `{ rows, unreadCount }` inside the envelope's
  /// `data` field (rather than a flat array) so the unread count always
  /// travels with the first page — see `notification.routes.js`.
  Future<NotificationPage> list({int page = 1}) async {
    final envelope = await _client.getEnvelope('/notifications', queryParameters: {'page': page, 'limit': 20});
    final data = envelope['data'] as Map<String, dynamic>? ?? const {};
    final rows = (data['rows'] as List<dynamic>? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = envelope['meta'] as Map<String, dynamic>?;
    final int currentPage = meta?['page'] as int? ?? 1;
    final int totalPages = meta?['totalPages'] as int? ?? 1;
    return NotificationPage(
      items: rows,
      unreadCount: data['unreadCount'] as int? ?? 0,
      hasMore: currentPage < totalPages,
    );
  }

  Future<void> markRead(String id) => _client.post('/notifications/$id/read');

  Future<void> markAllRead() => _client.post('/notifications/read-all');
}

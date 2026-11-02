class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['notification_type'] as String? ?? json['type'] as String? ?? 'general',
        data: (json['data'] as Map<String, dynamic>?) ?? const {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount, required this.hasMore});

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
}

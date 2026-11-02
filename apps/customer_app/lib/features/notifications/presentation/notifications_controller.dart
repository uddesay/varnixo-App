import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/providers/core_providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';

final Provider<NotificationRepository> notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = true,
    this.hasMore = true,
    this.error,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

/// Backs both the full notifications screen and the header bell badge:
/// hydrates from the REST feed, then keeps the unread count and list live
/// via the socket's `onNotification` stream for as long as this controller
/// (a single app-wide provider) stays alive.
class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._repository, SocketClient socketClient)
      : _socketClient = socketClient,
        super(const NotificationsState()) {
    refresh();
    _sub = _socketClient.onNotification.listen(_onLiveNotification);
  }

  final NotificationRepository _repository;
  final SocketClient _socketClient;
  late final StreamSubscription<Map<String, dynamic>> _sub;
  int _page = 1;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    _page = 1;
    try {
      final page = await _repository.list(page: 1);
      state = state.copyWith(
        items: page.items,
        unreadCount: page.unreadCount,
        isLoading: false,
        hasMore: page.hasMore,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    try {
      final page = await _repository.list(page: _page + 1);
      _page += 1;
      state = state.copyWith(items: [...state.items, ...page.items], hasMore: page.hasMore);
    } on ApiException {
      // Silently stop paginating; refresh() surfaces failures.
    }
  }

  void _onLiveNotification(Map<String, dynamic> payload) {
    final AppNotification notification = AppNotification.fromJson(payload);
    state = state.copyWith(
      items: [notification, ...state.items],
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> markRead(String id) async {
    final int index = state.items.indexWhere((n) => n.id == id);
    if (index == -1 || state.items[index].isRead) return;

    final List<AppNotification> updated = [...state.items];
    updated[index] = updated[index].copyWith(isRead: true);
    state = state.copyWith(items: updated, unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0);

    try {
      await _repository.markRead(id);
    } on ApiException {
      // Best-effort: leave the optimistic read state even if the write
      // failed — worst case it re-syncs on the next refresh().
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
    try {
      await _repository.markAllRead();
    } on ApiException {
      // Best-effort, same as markRead.
    }
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

final StateNotifierProvider<NotificationsController, NotificationsState> notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (ref) => NotificationsController(
    ref.watch(notificationRepositoryProvider),
    ref.watch(socketClientProvider),
  ),
);

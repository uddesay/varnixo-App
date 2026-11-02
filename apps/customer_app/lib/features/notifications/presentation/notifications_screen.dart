import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/notification.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationsControllerProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(error: state.error!, onRetry: () => ref.read(notificationsControllerProvider.notifier).refresh());
    }
    if (state.items.isEmpty) {
      return const EmptyStateView(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message: 'Order updates, offers and support replies will show up here.',
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 200) {
          ref.read(notificationsControllerProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _NotificationTile(notification: state.items[index]),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(notificationsControllerProvider.notifier).markRead(notification.id);

    final String? orderId = notification.data['orderId'] as String?;
    final String? ticketId = notification.data['ticketId'] as String?;
    if (orderId != null) {
      context.push(RoutePaths.orderDetailPath(orderId));
    } else if (ticketId != null) {
      context.push(RoutePaths.ticketDetailPath(ticketId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _open(context, ref),
      tileColor: notification.isRead ? null : scheme.primaryContainer.withOpacity(0.25),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(_iconFor(notification.type), color: scheme.onPrimaryContainer, size: 20),
      ),
      title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(notification.body),
      trailing: Text(
        formatRelativeTime(notification.createdAt),
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
      isThreeLine: false,
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('order_')) return Icons.local_shipping_outlined;
    if (type.startsWith('return_')) return Icons.assignment_return_outlined;
    if (type == 'support_reply') return Icons.support_agent_outlined;
    return Icons.notifications_none_rounded;
  }
}

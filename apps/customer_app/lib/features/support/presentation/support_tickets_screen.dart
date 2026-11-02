import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/support_ticket.dart';
import 'support_tickets_controller.dart';

const Map<String, Color> _statusColors = {
  'open': Colors.blue,
  'in_progress': Colors.amber,
  'waiting_on_customer': Colors.purple,
  'resolved': Colors.green,
  'closed': Colors.grey,
};

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.newSupportTicket),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New request'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(supportTicketsControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, SupportTicketsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(error: state.error!, onRetry: () => ref.read(supportTicketsControllerProvider.notifier).refresh());
    }
    if (state.items.isEmpty) {
      return const EmptyStateView(
        icon: Icons.support_agent_outlined,
        title: 'No support requests yet',
        message: 'Need help with an order or your account? Start a new request.',
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 200) {
          ref.read(supportTicketsControllerProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: state.items.length,
        itemBuilder: (context, index) => _TicketCard(ticket: state.items[index]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColors[ticket.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push(RoutePaths.ticketDetailPath(ticket.id)),
        title: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${ticket.ticketNumber} · ${formatRelativeTime(ticket.updatedAt)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            ticket.status.replaceAll('_', ' '),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_formatter.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/support_ticket.dart';
import 'ticket_thread_controller.dart';

class TicketThreadScreen extends ConsumerStatefulWidget {
  const TicketThreadScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends ConsumerState<TicketThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final String body = _messageController.text;
    if (body.trim().isEmpty) return;
    _messageController.clear();
    final bool sent =
        await ref.read(ticketThreadControllerProvider(widget.ticketId).notifier).sendMessage(body);
    if (sent) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketThreadControllerProvider(widget.ticketId));
    final String? myUserId = ref.watch(authControllerProvider).user?.id;
    final TicketDetail? ticket = state.ticket;

    ref.listen(ticketThreadControllerProvider(widget.ticketId), (previous, next) {
      if ((previous?.ticket?.messages.length ?? 0) != (next.ticket?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(ticket?.ticketNumber ?? 'Support')),
      body: state.isLoading && ticket == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && ticket == null
              ? ErrorView(
                  error: state.error!,
                  onRetry: () => ref.read(ticketThreadControllerProvider(widget.ticketId).notifier).refresh(),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(ticket!.subject, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.messages.length,
                        itemBuilder: (context, index) {
                          final message = ticket.messages[index];
                          final bool isMine = message.senderId == myUserId;
                          return _MessageBubble(isMine: isMine, message: message);
                        },
                      ),
                    ),
                    if (!ticket.isClosed)
                      _Composer(controller: _messageController, isSending: state.isSending, onSend: _send)
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'This request is ${ticket.status}. Start a new request if you need further help.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.isMine, required this.message});

  final bool isMine;
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.body, style: TextStyle(color: isMine ? scheme.onPrimary : scheme.onSurface)),
            const SizedBox(height: 4),
            Text(
              formatRelativeTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: (isMine ? scheme.onPrimary : scheme.onSurface).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.isSending, required this.onSend});

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

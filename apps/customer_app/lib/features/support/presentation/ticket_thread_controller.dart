import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/providers/core_providers.dart';
import '../data/support_repository.dart';
import '../domain/support_ticket.dart';
import 'support_providers.dart';

class TicketThreadState {
  const TicketThreadState({this.ticket, this.isLoading = true, this.isSending = false, this.error});

  final TicketDetail? ticket;
  final bool isLoading;
  final bool isSending;
  final Object? error;

  TicketThreadState copyWith({
    TicketDetail? ticket,
    bool? isLoading,
    bool? isSending,
    Object? error,
  }) =>
      TicketThreadState(
        ticket: ticket ?? this.ticket,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: error,
      );
}

/// One controller instance per ticket (`.family`), so navigating between
/// tickets doesn't leak socket subscriptions or stale state.
class TicketThreadController extends StateNotifier<TicketThreadState> {
  TicketThreadController(this._repository, SocketClient socketClient, this.ticketId)
      : _socketClient = socketClient,
        super(const TicketThreadState()) {
    _load();
    _sub = _socketClient.onSupportMessage.listen(_onLiveMessage);
  }

  final SupportRepository _repository;
  final SocketClient _socketClient;
  final String ticketId;
  late final StreamSubscription<Map<String, dynamic>> _sub;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ticket = await _repository.getTicket(ticketId);
      state = state.copyWith(ticket: ticket, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() => _load();

  void _onLiveMessage(Map<String, dynamic> payload) {
    if (payload['ticketId'] != ticketId) return;
    final current = state.ticket;
    if (current == null) return;
    final message = TicketMessage.fromJson(payload['message'] as Map<String, dynamic>);
    state = state.copyWith(ticket: current.copyWithMessages([...current.messages, message]));
  }

  Future<bool> sendMessage(String body) async {
    final current = state.ticket;
    if (current == null || body.trim().isEmpty) return false;

    state = state.copyWith(isSending: true);
    try {
      final message = await _repository.sendMessage(ticketId, body.trim());
      state = state.copyWith(
        isSending: false,
        ticket: current.copyWithMessages([...current.messages, message]),
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e);
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

final ticketThreadControllerProvider =
    StateNotifierProvider.family<TicketThreadController, TicketThreadState, String>(
  (ref, ticketId) => TicketThreadController(
    ref.watch(supportRepositoryProvider),
    ref.watch(socketClientProvider),
    ticketId,
  ),
);

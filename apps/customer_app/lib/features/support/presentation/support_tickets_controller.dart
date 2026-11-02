import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/support_repository.dart';
import '../domain/support_ticket.dart';
import 'support_providers.dart';

class SupportTicketsState {
  const SupportTicketsState({
    this.items = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.error,
  });

  final List<SupportTicket> items;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  SupportTicketsState copyWith({
    List<SupportTicket>? items,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) =>
      SupportTicketsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class SupportTicketsController extends StateNotifier<SupportTicketsState> {
  SupportTicketsController(this._repository) : super(const SupportTicketsState()) {
    refresh();
  }

  final SupportRepository _repository;
  int _page = 1;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    _page = 1;
    try {
      final result = await _repository.listTickets(page: 1);
      state = state.copyWith(items: result.items, isLoading: false, hasMore: result.hasMore);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    try {
      final result = await _repository.listTickets(page: _page + 1);
      _page += 1;
      state = state.copyWith(items: [...state.items, ...result.items], hasMore: result.hasMore);
    } on ApiException {
      // Silently stop paginating; refresh() surfaces failures.
    }
  }
}

final StateNotifierProvider<SupportTicketsController, SupportTicketsState> supportTicketsControllerProvider =
    StateNotifierProvider<SupportTicketsController, SupportTicketsState>(
  (ref) => SupportTicketsController(ref.watch(supportRepositoryProvider)),
);

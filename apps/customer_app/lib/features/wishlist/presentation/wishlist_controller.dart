import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/wishlist_repository.dart';

final Provider<WishlistRepository> wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(ref.watch(apiClientProvider)),
);

class WishlistState {
  const WishlistState({
    this.items = const [],
    this.isLoading = true,
    this.error,
    this.pendingIds = const {},
  });

  final List<WishlistItem> items;
  final bool isLoading;
  final Object? error;

  /// Product ids with an add/remove request in flight — lets tiles show a
  /// per-item spinner instead of freezing the whole grid on one tap.
  final Set<String> pendingIds;

  Set<String> get productIds => items.map((e) => e.product.id).toSet();

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    Object? error,
    Set<String>? pendingIds,
  }) =>
      WishlistState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        pendingIds: pendingIds ?? this.pendingIds,
      );
}

/// Wishlist is kept as global app state (not per-screen) so the heart icon
/// on every product card — home, category grid, search, PDP — stays in
/// sync without each screen re-fetching.
class WishlistController extends StateNotifier<WishlistState> {
  WishlistController(this._repository) : super(const WishlistState()) {
    refresh();
  }

  final WishlistRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.list();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  bool isWishlisted(String productId) => state.productIds.contains(productId);

  Future<void> toggle(String productId) async {
    final bool currentlyWishlisted = isWishlisted(productId);
    state = state.copyWith(pendingIds: {...state.pendingIds, productId});
    try {
      if (currentlyWishlisted) {
        await _repository.remove(productId);
        state = state.copyWith(
          items: state.items.where((e) => e.product.id != productId).toList(),
        );
      } else {
        await _repository.add(productId);
        await refresh();
      }
    } on ApiException {
      // Leave state as-is; the toggle UI reverts since the optimistic
      // change was never applied — only the pending flag is cleared below.
    } finally {
      state = state.copyWith(
        pendingIds: {...state.pendingIds}..remove(productId),
      );
    }
  }
}

final StateNotifierProvider<WishlistController, WishlistState> wishlistControllerProvider =
    StateNotifierProvider<WishlistController, WishlistState>(
  (ref) => WishlistController(ref.watch(wishlistRepositoryProvider)),
);

final Provider<int> wishlistCountProvider =
    Provider<int>((ref) => ref.watch(wishlistControllerProvider).items.length);

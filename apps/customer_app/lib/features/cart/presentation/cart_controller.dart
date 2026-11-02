import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/cart_repository.dart';
import '../domain/cart.dart';

final Provider<CartRepository> cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(apiClientProvider)),
);

class CartState {
  const CartState({this.cart, this.isLoading = true, this.isMutating = false, this.error});

  final Cart? cart;
  final bool isLoading;

  /// True while an add/update/remove/coupon call is in flight — used to
  /// disable quantity steppers so rapid taps can't race each other.
  final bool isMutating;
  final Object? error;

  CartState copyWith({Cart? cart, bool? isLoading, bool? isMutating, Object? error}) => CartState(
        cart: cart ?? this.cart,
        isLoading: isLoading ?? this.isLoading,
        isMutating: isMutating ?? this.isMutating,
        error: error,
      );
}

/// Global cart state — every "add to cart" across the app (PDP, related
/// products, search) goes through this single controller so the badge
/// count and cart screen never drift out of sync.
class CartController extends StateNotifier<CartState> {
  CartController(this._repository) : super(const CartState()) {
    refresh();
  }

  final CartRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _repository.getCart();
      state = state.copyWith(cart: cart, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<ApiException?> addItem({required String variantId, int quantity = 1}) =>
      _mutate(() => _repository.addItem(variantId: variantId, quantity: quantity));

  Future<ApiException?> updateQuantity(String itemId, int quantity) =>
      _mutate(() => _repository.updateItem(itemId, quantity: quantity));

  Future<ApiException?> saveForLater(String itemId, bool save) =>
      _mutate(() => _repository.updateItem(itemId, saveForLater: save));

  Future<ApiException?> removeItem(String itemId) =>
      _mutate(() => _repository.removeItem(itemId));

  Future<ApiException?> applyCoupon(String code) =>
      _mutate(() => _repository.applyCoupon(code));

  Future<ApiException?> removeCoupon() => _mutate(_repository.removeCoupon);

  Future<ApiException?> _mutate(Future<Cart> Function() action) async {
    state = state.copyWith(isMutating: true);
    try {
      final cart = await action();
      state = state.copyWith(cart: cart, isMutating: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isMutating: false);
      return e;
    }
  }
}

final StateNotifierProvider<CartController, CartState> cartControllerProvider =
    StateNotifierProvider<CartController, CartState>(
  (ref) => CartController(ref.watch(cartRepositoryProvider)),
);

final Provider<int> cartItemCountProvider =
    Provider<int>((ref) => ref.watch(cartControllerProvider).cart?.totals.itemCount ?? 0);

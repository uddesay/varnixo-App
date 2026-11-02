import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/checkout_repository.dart';

final Provider<CheckoutRepository> checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(ref.watch(apiClientProvider)),
);

/// "Buy Now" totals preview — a single-item, read-only view of what
/// `computeTotals` would produce, fetched fresh per selection so stock/price
/// changes are reflected right up to the moment of checkout.
final buyNowPreviewProvider = FutureProvider.family<Cart, BuyNowSelection>(
  (ref, selection) => ref.watch(cartRepositoryProvider).previewBuyNow(
        variantId: selection.variantId,
        quantity: selection.quantity,
      ),
);

class CheckoutState {
  const CheckoutState({
    this.selectedAddressId,
    this.paymentMethod = 'cod',
    this.useWallet = false,
    this.isPlacingOrder = false,
    this.buyNowSelection,
    this.error,
  });

  final String? selectedAddressId;
  final String paymentMethod;
  final bool useWallet;
  final bool isPlacingOrder;

  /// Non-null when this checkout was entered via "Buy Now" — in that mode
  /// the order is created from this single item instead of the cart, and
  /// the cart is left untouched.
  final BuyNowSelection? buyNowSelection;
  final Object? error;

  CheckoutState copyWith({
    String? selectedAddressId,
    String? paymentMethod,
    bool? useWallet,
    bool? isPlacingOrder,
    BuyNowSelection? buyNowSelection,
    bool clearBuyNow = false,
    Object? error,
  }) =>
      CheckoutState(
        selectedAddressId: selectedAddressId ?? this.selectedAddressId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        useWallet: useWallet ?? this.useWallet,
        isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
        buyNowSelection: clearBuyNow ? null : (buyNowSelection ?? this.buyNowSelection),
        error: error,
      );
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._ref) : super(const CheckoutState());

  final Ref _ref;

  CheckoutRepository get _repository => _ref.read(checkoutRepositoryProvider);

  void selectAddress(String addressId) =>
      state = state.copyWith(selectedAddressId: addressId);

  void selectPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void toggleUseWallet(bool value) => state = state.copyWith(useWallet: value);

  /// Enters "Buy Now" mode — resets any leftover COD/wallet selection from a
  /// prior checkout so a stale wallet toggle can't silently apply here.
  void setBuyNow(BuyNowSelection selection) => state = CheckoutState(
        selectedAddressId: state.selectedAddressId,
        buyNowSelection: selection,
      );

  void clearBuyNow() => state = state.copyWith(clearBuyNow: true);

  /// Wallet can cover at most the cart total; capped client-side purely for
  /// display — the server re-validates and clamps authoritatively.
  int walletMinorToUse(int walletBalanceMinor, int cartTotalMinor) {
    if (!state.useWallet) return 0;
    return walletBalanceMinor < cartTotalMinor ? walletBalanceMinor : cartTotalMinor;
  }

  Future<OrderCreateResult?> placeOrder({required int useWalletMinor}) async {
    if (state.selectedAddressId == null) {
      state = state.copyWith(error: const ApiException(message: 'Select a delivery address'));
      return null;
    }
    state = state.copyWith(isPlacingOrder: true, error: null);
    try {
      final result = await _repository.createOrder(
        addressId: state.selectedAddressId!,
        paymentMethod: state.paymentMethod,
        useWalletMinor: useWalletMinor,
        buyNow: state.buyNowSelection,
      );
      state = state.copyWith(isPlacingOrder: false);
      // Buy Now never touches the persisted cart, so there's nothing to
      // refresh there.
      if (state.buyNowSelection == null) {
        unawaited(_ref.read(cartControllerProvider.notifier).refresh());
      }
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(isPlacingOrder: false, error: e);
      return null;
    }
  }

  Future<PaymentIntentResult?> createPaymentIntent(String orderId) async {
    try {
      return await _repository.createPaymentIntent(orderId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }
}

final StateNotifierProvider<CheckoutController, CheckoutState> checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>(
  (ref) => CheckoutController(ref),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../addresses/domain/address.dart';
import '../../addresses/presentation/address_controller.dart';
import '../../addresses/presentation/widgets/address_form_sheet.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'checkout_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final Razorpay _razorpay = Razorpay();
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    if (_pendingOrderId == null) return;
    try {
      await ref.read(checkoutRepositoryProvider).confirmRazorpayPayment(
            rpOrderId: response.orderId!,
            rpPaymentId: response.paymentId!,
            signature: response.signature!,
          );
      if (mounted) context.go(RoutePaths.orderSuccessPath(_pendingOrderId!));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Check Orders for status.')),
        );
      }
    }
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? 'Please try again'}')),
    );
  }

  /// Sources totals from the Buy Now preview when active, otherwise the
  /// persisted cart — the two checkout entry points share this screen but
  /// never share data, so a stray cart item can't sneak into a Buy Now order.
  Cart? _readCart() {
    final buyNow = ref.read(checkoutControllerProvider).buyNowSelection;
    if (buyNow != null) return ref.read(buyNowPreviewProvider(buyNow)).valueOrNull;
    return ref.read(cartControllerProvider).cart;
  }

  Future<void> _placeOrder() async {
    final checkoutState = ref.read(checkoutControllerProvider);
    final cart = _readCart();
    final walletBalance = ref.read(walletBalanceProvider).valueOrNull;
    if (cart == null) return;

    final int useWalletMinor = checkoutState.useWallet && walletBalance != null
        ? ref
            .read(checkoutControllerProvider.notifier)
            .walletMinorToUse(walletBalance.balanceMinor, cart.totals.totalMinor)
        : 0;

    final result = await ref
        .read(checkoutControllerProvider.notifier)
        .placeOrder(useWalletMinor: useWalletMinor);
    if (result == null) {
      final error = ref.read(checkoutControllerProvider).error;
      if (mounted) {
        final String message =
            error is ApiException ? error.message : 'Could not place order';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    if (!result.requiresPayment) {
      if (mounted) context.go(RoutePaths.orderSuccessPath(result.orderId));
      return;
    }

    _pendingOrderId = result.orderId;
    final intent = await ref
        .read(checkoutControllerProvider.notifier)
        .createPaymentIntent(result.orderId);
    if (intent == null || !mounted) return;

    if (intent.provider == 'razorpay') {
      _razorpay.open({
        'key': intent.keyId ?? Env.razorpayKeyId,
        'order_id': intent.intentId,
        'amount': intent.amountMinor,
        'currency': intent.currency,
        'name': 'Varnixo',
        'description': 'Order payment',
      });
    } else {
      // Stripe PaymentSheet integration point: intent.clientSecret is ready
      // — wire flutter_stripe's PaymentSheet here once platform keys are
      // configured for iOS/Android via `flutter create .`.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card payment checkout is not yet wired in this build.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressControllerProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final buyNow = checkoutState.buyNowSelection;

    Cart? cart;
    String? loadError;
    if (buyNow != null) {
      final preview = ref.watch(buyNowPreviewProvider(buyNow));
      cart = preview.valueOrNull;
      if (preview.hasError) loadError = 'This item is no longer available.';
    } else {
      cart = ref.watch(cartControllerProvider).cart;
    }

    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }
    if (cart == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Preselect the default address once addresses have loaded.
    if (checkoutState.selectedAddressId == null && addressState.defaultAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(checkoutControllerProvider.notifier)
            .selectAddress(addressState.defaultAddress!.id);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (buyNow != null) ...[
            const _SectionTitle(title: 'Buying'),
            ...cart.items.map((item) => _BuyNowItemTile(item: item)),
            const SizedBox(height: 24),
          ],
          _SectionTitle(title: 'Delivery address', action: TextButton(
            onPressed: () => showAddressFormSheet(context),
            child: const Text('Add new'),
          ),),
          ...addressState.addresses.map(
            (address) => _AddressTile(
              address: address,
              isSelected: checkoutState.selectedAddressId == address.id,
              onSelect: () =>
                  ref.read(checkoutControllerProvider.notifier).selectAddress(address.id),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Payment method'),
          _PaymentMethodTile(
            label: 'Cash on Delivery',
            icon: Icons.payments_outlined,
            value: 'cod',
            groupValue: checkoutState.paymentMethod,
            onChanged: ref.read(checkoutControllerProvider.notifier).selectPaymentMethod,
          ),
          _PaymentMethodTile(
            label: 'Card / UPI / Netbanking',
            icon: Icons.credit_card_rounded,
            value: 'razorpay',
            groupValue: checkoutState.paymentMethod,
            onChanged: ref.read(checkoutControllerProvider.notifier).selectPaymentMethod,
          ),
          const SizedBox(height: 16),
          walletAsync.when(
            data: (wallet) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Use wallet balance (${CurrencyFormatter.format(wallet.balanceMinor)})'),
              value: checkoutState.useWallet,
              onChanged: wallet.balanceMinor > 0
                  ? ref.read(checkoutControllerProvider.notifier).toggleUseWallet
                  : null,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Order summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summaryRow('Subtotal', CurrencyFormatter.format(cart.totals.subtotalMinor)),
                  if (cart.totals.discountMinor > 0)
                    _summaryRow('Discount', '-${CurrencyFormatter.format(cart.totals.discountMinor)}'),
                  _summaryRow(
                    'Shipping',
                    cart.totals.shippingMinor == 0
                        ? 'FREE'
                        : CurrencyFormatter.format(cart.totals.shippingMinor),
                  ),
                  const Divider(height: 24),
                  _summaryRow('Total', CurrencyFormatter.format(cart.totals.totalMinor), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Place Order',
            isLoading: checkoutState.isPlacingOrder,
            onPressed: checkoutState.selectedAddressId == null ? null : _placeOrder,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (action != null) action!,
          ],
        ),
      );
}

class _BuyNowItemTile extends StatelessWidget {
  const _BuyNowItemTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [if (item.optionsLabel.isNotEmpty) item.optionsLabel, 'Qty ${item.quantity}'].join(' · '),
        ),
        trailing: Text(
          CurrencyFormatter.format(item.lineTotalMinor),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.isSelected, required this.onSelect});
  final Address address;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RadioListTile<String>(
        value: address.id,
        groupValue: isSelected ? address.id : null,
        onChanged: (_) => onSelect(),
        title: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${address.formatted}\n${address.recipientPhone}'),
        isThreeLine: true,
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        secondary: Icon(icon),
        title: Text(label),
      ),
    );
  }
}

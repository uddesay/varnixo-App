import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/network_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../../checkout/presentation/checkout_controller.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cartControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
      bottomNavigationBar: (state.cart != null && !state.cart!.isEmpty)
          ? _CheckoutBar(cart: state.cart!, isMutating: state.isMutating)
          : null,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CartState state) {
    if (state.isLoading && state.cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.cart == null) {
      return ErrorView(
        error: state.error!,
        onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
      );
    }
    final Cart cart = state.cart!;
    if (cart.isEmpty && cart.savedForLater.isEmpty) {
      return EmptyStateView(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Add items to get started.',
        actionLabel: 'Browse products',
        onAction: () => context.go(RoutePaths.home),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cart.hasUnpurchasableItems)
          _Banner(text: 'Some items are no longer available and won\'t be charged.'),
        ...cart.items.map((item) => _CartItemTile(item: item, isSaved: false)),
        if (cart.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          _CouponSection(coupon: cart.totals.coupon, error: cart.totals.couponError),
          const SizedBox(height: 16),
          _TotalsSummary(totals: cart.totals),
        ],
        if (cart.savedForLater.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Saved for later', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...cart.savedForLater.map((item) => _CartItemTile(item: item, isSaved: true)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item, required this.isSaved});

  final CartItem item;
  final bool isSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartControllerProvider.notifier);
    final bool isMutating = ref.watch(cartControllerProvider).isMutating;

    return Opacity(
      opacity: item.purchasable ? 1 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: AppNetworkImage(url: item.image, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (item.optionsLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.optionsLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(item.unitPriceMinor),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isSaved)
                          _QuantityStepper(
                            quantity: item.quantity,
                            maxQuantity: item.availableStock,
                            isDisabled: isMutating,
                            onChanged: (qty) => notifier.updateQuantity(item.itemId, qty),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: isMutating
                              ? null
                              : () => notifier.saveForLater(item.itemId, !isSaved),
                          child: Text(isSaved ? 'Move to cart' : 'Save for later'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: isMutating ? null : () => notifier.removeItem(item.itemId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.isDisabled,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final bool isDisabled;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 16,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove),
            onPressed: (isDisabled || quantity <= 1) ? null : () => onChanged(quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$quantity'),
          ),
          IconButton(
            iconSize: 16,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add),
            onPressed:
                (isDisabled || quantity >= maxQuantity) ? null : () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _CouponSection extends ConsumerStatefulWidget {
  const _CouponSection({this.coupon, this.error});
  final CartCoupon? coupon;
  final String? error;

  @override
  ConsumerState<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<_CouponSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coupon != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.local_offer_rounded, color: AppColors.success),
          title: Text(widget.coupon!.code, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(widget.coupon!.title),
          trailing: TextButton(
            onPressed: () => ref.read(cartControllerProvider.notifier).removeCoupon(),
            child: const Text('Remove'),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Enter coupon code',
                  border: InputBorder.none,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final code = _controller.text.trim();
                if (code.isEmpty) return;
                final error =
                    await ref.read(cartControllerProvider.notifier).applyCoupon(code);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsSummary extends StatelessWidget {
  const _TotalsSummary({required this.totals});
  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'Subtotal', CurrencyFormatter.format(totals.subtotalMinor)),
            if (totals.discountMinor > 0)
              _row(context, 'Discount', '-${CurrencyFormatter.format(totals.discountMinor)}',
                  color: AppColors.success,),
            _row(
              context,
              'Shipping',
              totals.shippingMinor == 0 ? 'FREE' : CurrencyFormatter.format(totals.shippingMinor),
              color: totals.shippingMinor == 0 ? AppColors.success : null,
            ),
            if (totals.amountToFreeShipping > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Add ${CurrencyFormatter.format(totals.amountToFreeShipping)} more for free shipping',
                  style: const TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ),
            const Divider(height: 24),
            _row(
              context,
              'Total',
              CurrencyFormatter.format(totals.totalMinor),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      fontSize: isBold ? 16 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({required this.cart, required this.isMutating});
  final Cart cart;
  final bool isMutating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(cart.totals.totalMinor),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('${cart.totals.itemCount} item(s)', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: 'Checkout',
                isLoading: isMutating,
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        // Clears any leftover "Buy Now" selection from a
                        // previous single-item checkout so this cart
                        // checkout can't accidentally reuse it.
                        ref.read(checkoutControllerProvider.notifier).clearBuyNow();
                        context.push(RoutePaths.checkout);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

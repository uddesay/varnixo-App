import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/network_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/price_tag.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/presentation/checkout_controller.dart';
import '../../wishlist/presentation/wishlist_controller.dart';
import '../domain/product_detail.dart';
import 'catalog_providers.dart';
import 'widgets/product_rail.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, String> _selectedOptions = {};
  int _quantity = 1;
  bool _initialized = false;

  void _initSelection(ProductDetail product) {
    if (_initialized) return;
    for (final option in product.defaultVariant.options) {
      _selectedOptions[option.name] = option.value;
    }
    _initialized = true;
  }

  ProductVariant? _matchingVariant(ProductDetail product) {
    for (final variant in product.variants) {
      final bool matches = product.optionNames.every(
        (name) => variant.optionValue(name) == _selectedOptions[name],
      );
      if (matches) return variant;
    }
    return null;
  }

  Future<void> _addToCart(ProductVariant variant) async {
    final error = await ref
        .read(cartControllerProvider.notifier)
        .addItem(variantId: variant.id, quantity: _quantity);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        action: SnackBarAction(label: 'View cart', onPressed: () => context.push(RoutePaths.cart)),
      ),
    );
  }

  /// Checks out exactly this item — never touches the persisted cart, so
  /// whatever else is already in it is left alone.
  void _buyNow(ProductVariant variant) {
    ref.read(checkoutControllerProvider.notifier).setBuyNow(
          BuyNowSelection(variantId: variant.id, quantity: _quantity),
        );
    context.push(RoutePaths.checkout);
  }

  void _shareProduct(ProductDetail product) {
    final price = CurrencyFormatter.format(product.defaultVariant.salePriceMinor);
    Share.share('${product.title} — $price on Varnixo');
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productDetailProvider(widget.slug)),
        ),
        data: (product) {
          _initSelection(product);
          final ProductVariant? selectedVariant = _matchingVariant(product);
          return _buildContent(context, product, selectedVariant);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductDetail product, ProductVariant? variant) {
    final relatedAsync = ref.watch(relatedProductsProvider(widget.slug));
    final bool isWishlisted = ref.watch(wishlistControllerProvider).productIds.contains(product.id);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 340,
              actions: [
                IconButton(
                  icon: Icon(isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  color: isWishlisted ? Colors.redAccent : null,
                  onPressed: () =>
                      ref.read(wishlistControllerProvider.notifier).toggle(product.id),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareProduct(product),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: product.media.isEmpty
                    ? const AppNetworkImage(url: null)
                    : CarouselSlider(
                        options: CarouselOptions(
                          height: 340,
                          viewportFraction: 1,
                          enableInfiniteScroll: false,
                        ),
                        items: product.media
                            .map((m) => AppNetworkImage(url: m.thumbnailUrl ?? m.url))
                            .toList(),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brandName != null)
                      Text(
                        product.brandName!.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    Text(product.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (product.ratingAvg > 0)
                          RatingBadge(rating: product.ratingAvg, count: product.ratingCount),
                        const SizedBox(width: 8),
                        if (product.vendorName != null)
                          Expanded(
                            child: Text(
                              'Sold by ${product.vendorName}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PriceTag(
                      priceMinor: (variant ?? product.defaultVariant).salePriceMinor,
                      mrpMinor: (variant ?? product.defaultVariant).mrpMinor,
                    ),
                    const SizedBox(height: 16),
                    ...product.optionNames.map(
                      (name) => _OptionSelector(
                        product: product,
                        optionName: name,
                        selected: _selectedOptions[name],
                        onSelected: (value) => setState(() => _selectedOptions[name] = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (variant != null && !variant.inStock)
                      const Text('Out of stock', style: TextStyle(color: AppColors.error)),
                    if (variant != null && variant.inStock) _QuantityRow(
                      quantity: _quantity,
                      max: variant.availableStock,
                      onChanged: (q) => setState(() => _quantity = q),
                    ),
                    const SizedBox(height: 20),
                    if (product.highlights.isNotEmpty) ...[
                      Text('Highlights', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...product.highlights.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(child: Text(h)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('Description', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(product.description),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          product.isCodAvailable ? Icons.local_shipping_outlined : Icons.block,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(product.isCodAvailable ? 'Cash on Delivery available' : 'COD not available'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.replay_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          product.isReturnable
                              ? '${product.returnWindowDays}-day return policy'
                              : 'Not returnable',
                        ),
                      ],
                    ),
                    if (product.specifications.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Specifications', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _SpecificationsTable(specifications: product.specifications),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: relatedAsync.maybeWhen(
                data: (items) => Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: ProductRail(title: 'You may also like', products: items),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add to Cart',
                      outlined: true,
                      onPressed: variant != null && variant.inStock
                          ? () => _addToCart(variant)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Buy Now',
                      onPressed: variant != null && variant.inStock
                          ? () => _buyNow(variant)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.product,
    required this.optionName,
    required this.selected,
    required this.onSelected,
  });

  final ProductDetail product;
  final String optionName;
  final String? selected;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) {
    final List<String> values = product.variants
        .expand((v) => v.options.where((o) => o.name == optionName).map((o) => o.value))
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(optionName, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onSelected(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({required this.quantity, required this.max, required this.onChanged});
  final int quantity;
  final int max;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Quantity', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Text('$quantity'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

class _SpecificationsTable extends StatelessWidget {
  const _SpecificationsTable({required this.specifications});
  final List<ProductSpecification> specifications;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ProductSpecification>> grouped = {};
    for (final spec in specifications) {
      grouped.putIfAbsent(spec.group, () => []).add(spec);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...entry.value.map(
                (spec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          spec.key,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Expanded(child: Text(spec.value)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/network_image.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../../../wishlist/presentation/wishlist_controller.dart';
import '../../domain/product_card.dart';

/// Standard product tile used across home sections, category grids, search
/// results, wishlist and related-products carousels — one visual language
/// for "a product" everywhere it appears.
class ProductGridTile extends ConsumerWidget {
  const ProductGridTile({required this.product, super.key});

  final ProductCard product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistControllerProvider);
    final bool isWishlisted = wishlistState.productIds.contains(product.id);
    final bool isPending = wishlistState.pendingIds.contains(product.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(RoutePaths.productPath(product.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppNetworkImage(
                    url: product.imageUrl,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _WishlistButton(
                    isWishlisted: isWishlisted,
                    isPending: isPending,
                    onTap: () => ref.read(wishlistControllerProvider.notifier).toggle(product.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          if (product.ratingAvg > 0) ...[
            RatingBadge(rating: product.ratingAvg, count: product.ratingCount, small: true),
            const SizedBox(height: 4),
          ],
          PriceTag(
            priceMinor: product.priceMinor,
            mrpMinor: product.mrpMinor,
            compact: true,
            priceStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.isWishlisted, required this.isPending, required this.onTap});

  final bool isWishlisted;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isPending ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: isPending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: isWishlisted ? Colors.redAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

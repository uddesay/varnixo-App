import 'package:flutter/material.dart';

import '../../domain/product_card.dart';
import 'product_grid_tile.dart';

/// Horizontally scrolling product showcase — "New Arrivals", "Trending
/// Now", "You may also like" all use this same shell.
class ProductRail extends StatelessWidget {
  const ProductRail({required this.title, required this.products, super.key});

  final String title;
  final List<ProductCard> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 150,
              child: ProductGridTile(product: products[index]),
            ),
          ),
        ),
      ],
    );
  }
}

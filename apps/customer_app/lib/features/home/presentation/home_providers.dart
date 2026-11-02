import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/product_card.dart';
import '../../catalog/presentation/catalog_providers.dart';

final FutureProvider<List<ProductCard>> newArrivalsProvider =
    FutureProvider<List<ProductCard>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).listProducts(
        const ProductListParams(sort: 'newest', limit: 8),
      );
  return result.items;
});

final FutureProvider<List<ProductCard>> trendingProvider =
    FutureProvider<List<ProductCard>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).listProducts(
        const ProductListParams(sort: 'popularity', limit: 8),
      );
  return result.items;
});

final FutureProvider<List<ProductCard>> recentlyViewedProvider =
    FutureProvider<List<ProductCard>>(
  (ref) => ref.watch(catalogRepositoryProvider).getRecentlyViewed(),
);

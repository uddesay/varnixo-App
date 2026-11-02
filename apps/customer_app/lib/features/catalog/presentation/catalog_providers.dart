import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/product_card.dart';
import '../domain/product_detail.dart';

final Provider<CatalogRepository> catalogRepositoryProvider =
    Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

final FutureProvider<List<Category>> categoryTreeProvider =
    FutureProvider<List<Category>>(
        (ref) => ref.watch(catalogRepositoryProvider).getCategoryTree(),);

final productDetailProvider =
    FutureProvider.family<ProductDetail, String>((ref, slug) async {
  final detail =
      await ref.watch(catalogRepositoryProvider).getProductBySlug(slug);
  // Fire-and-forget: personalization signal, must never block the PDP render.
  unawaited(
      ref.watch(catalogRepositoryProvider).trackRecentlyViewed(detail.id),);
  return detail;
});

final relatedProductsProvider =
    FutureProvider.family<List<ProductCard>, String>(
  (ref, slug) => ref.watch(catalogRepositoryProvider).getRelatedProducts(slug),
);

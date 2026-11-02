import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/catalog_repository.dart';
import '../domain/product_card.dart';
import 'catalog_providers.dart';

class ProductListState {
  const ProductListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.sort = 'newest',
    this.priceMin,
    this.priceMax,
    this.rating,
    this.error,
  });

  final List<ProductCard> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String sort;
  final int? priceMin;
  final int? priceMax;
  final double? rating;
  final Object? error;

  ProductListState copyWith({
    List<ProductCard>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? sort,
    int? priceMin,
    int? priceMax,
    double? rating,
    Object? error,
    bool clearError = false,
  }) =>
      ProductListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        sort: sort ?? this.sort,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        rating: rating ?? this.rating,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Infinite-scroll product grid, shared by category browsing and (via its
/// own [SearchController]) conceptually mirrored for search results.
class ProductListController extends StateNotifier<ProductListState> {
  ProductListController(this._repository, {this.categorySlug, this.brandSlug})
      : super(const ProductListState()) {
    loadFirstPage();
  }

  final CatalogRepository _repository;
  final String? categorySlug;
  final String? brandSlug;

  int _page = 1;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    _page = 1;
    try {
      final result = await _repository.listProducts(ProductListParams(
        page: 1,
        category: categorySlug,
        brand: brandSlug,
        sort: state.sort,
        priceMin: state.priceMin,
        priceMax: state.priceMax,
        rating: state.rating,
      ),);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.hasMore,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.listProducts(ProductListParams(
        page: _page + 1,
        category: categorySlug,
        brand: brandSlug,
        sort: state.sort,
        priceMin: state.priceMin,
        priceMax: state.priceMax,
        rating: state.rating,
      ),);
      _page += 1;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
      );
    } on ApiException {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> applyFilters(
      {String? sort, int? priceMin, int? priceMax, double? rating,}) async {
    state = state.copyWith(
        sort: sort, priceMin: priceMin, priceMax: priceMax, rating: rating,);
    await loadFirstPage();
  }
}

class CategoryKey {
  const CategoryKey({this.categorySlug, this.brandSlug});
  final String? categorySlug;
  final String? brandSlug;

  @override
  bool operator ==(Object other) =>
      other is CategoryKey &&
      other.categorySlug == categorySlug &&
      other.brandSlug == brandSlug;

  @override
  int get hashCode => Object.hash(categorySlug, brandSlug);
}

final productListControllerProvider = StateNotifierProvider.family<
    ProductListController, ProductListState, CategoryKey>(
  (ref, key) => ProductListController(
    ref.watch(catalogRepositoryProvider),
    categorySlug: key.categorySlug,
    brandSlug: key.brandSlug,
  ),
);

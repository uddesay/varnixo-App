import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../catalog/domain/product_card.dart';
import '../../catalog/presentation/catalog_providers.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
  });

  final String query;
  final List<ProductCard> results;
  final bool isLoading;
  final bool hasSearched;
  final Object? error;

  SearchState copyWith({
    String? query,
    List<ProductCard>? results,
    bool? isLoading,
    bool? hasSearched,
    Object? error,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        hasSearched: hasSearched ?? this.hasSearched,
        error: error,
      );
}

/// Debounces keystrokes (400ms) so the API isn't hit on every character —
/// mirrors the Elasticsearch-backed `/search` endpoint's autocomplete UX.
class ProductSearchController extends StateNotifier<SearchState> {
  ProductSearchController(this._ref) : super(const SearchState());

  final Ref _ref;
  Timer? _debounce;

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], hasSearched: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _ref.read(catalogRepositoryProvider).search(query: query);
      state = state.copyWith(results: result.items, isLoading: false, hasSearched: true);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e, hasSearched: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<ProductSearchController, SearchState> searchControllerProvider =
    StateNotifierProvider<ProductSearchController, SearchState>(
  (ref) => ProductSearchController(ref),
);

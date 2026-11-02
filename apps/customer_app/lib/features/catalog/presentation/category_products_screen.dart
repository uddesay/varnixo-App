import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'product_list_controller.dart';
import 'widgets/product_grid_tile.dart';
import 'widgets/sort_filter_sheet.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  late final CategoryKey _key = CategoryKey(categorySlug: widget.slug);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productListControllerProvider(_key).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListControllerProvider(_key));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.slug.replaceAll('-', ' ')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => SortFilterSheet(
                currentSort: state.sort,
                onApply: (sort, priceMin, priceMax, rating) => ref
                    .read(productListControllerProvider(_key).notifier)
                    .applyFilters(sort: sort, priceMin: priceMin, priceMax: priceMax, rating: rating),
              ),
            ),
          ),
        ],
      ),
      body: _body(state),
    );
  }

  Widget _body(ProductListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const ProductGridSkeleton(itemCount: 8);
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () => ref.read(productListControllerProvider(_key).notifier).loadFirstPage(),
      );
    }
    if (state.items.isEmpty) {
      return const Center(child: Text('No products found'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(productListControllerProvider(_key).notifier).loadFirstPage(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return ProductGridTile(product: state.items[index]);
        },
      ),
    );
  }
}

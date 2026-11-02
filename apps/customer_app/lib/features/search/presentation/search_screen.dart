import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../catalog/presentation/widgets/product_grid_tile.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products, brands...',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchControllerProvider.notifier).onQueryChanged(value),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                ref.read(searchControllerProvider.notifier).onQueryChanged('');
                setState(() {});
              },
            ),
        ],
      ),
      body: _body(state),
    );
  }

  Widget _body(SearchState state) {
    if (!state.hasSearched && !state.isLoading) {
      return const EmptyStateView(
        icon: Icons.search_rounded,
        title: 'Search Varnixo',
        message: 'Find products across every category and seller.',
      );
    }
    if (state.isLoading && state.results.isEmpty) {
      return const ProductGridSkeleton(itemCount: 6);
    }
    if (state.error != null && state.results.isEmpty) {
      return ErrorView(error: state.error!);
    }
    if (state.results.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No results for "${state.query}"',
        message: 'Try a different keyword or check your spelling.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) => ProductGridTile(product: state.results[index]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../catalog/presentation/widgets/product_grid_tile.dart';
import 'wishlist_controller.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(wishlistControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, WishlistState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const ProductGridSkeleton(itemCount: 6);
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () => ref.read(wishlistControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'Your wishlist is empty',
        message: 'Save items you love and find them here anytime.',
        actionLabel: 'Start shopping',
        onAction: () => context.go(RoutePaths.home),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) => ProductGridTile(product: state.items[index].product),
    );
  }
}

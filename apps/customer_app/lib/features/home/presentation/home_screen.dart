import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/network_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../catalog/presentation/widgets/product_rail.dart';
import '../../notifications/presentation/notifications_controller.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final categoriesAsync = ref.watch(categoryTreeProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final trendingAsync = ref.watch(trendingProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryTreeProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(trendingProvider);
          ref.invalidate(recentlyViewedProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: 16,
              title: Text(
                user != null
                    ? 'Hi, ${user.fullName.split(' ').first} 👋'
                    : 'Varnixo.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              actions: [
                _NotificationBellButton(
                  unreadCount:
                      ref.watch(notificationsControllerProvider).unreadCount,
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _SearchBar(onTap: () => context.push(RoutePaths.search)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF352945),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.local_mall_outlined,
                          size: 260,
                          color: Color(0x187F65A3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THE EVERYDAY, ELEVATED',
                              style: TextStyle(
                                color: Color(0xFFD2B9E9),
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Good things.\nGreat finds.\nAll yours.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                height: 1.12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Discover a little more of what you love.',
                              style: TextStyle(
                                color: Color(0xFFD8CDE3),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF0E5F8),
                                foregroundColor: const Color(0xFF352945),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => context.push(RoutePaths.search),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 17),
                              label: const Text('Explore the collection'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => _CategoryStrip(categories: categories),
                loading: () => const SizedBox(height: 90),
                error: (error, stack) => _InlineSectionError(
                  height: 90,
                  onRetry: () => ref.invalidate(categoryTreeProvider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: newArrivalsAsync.when(
                data: (products) =>
                    ProductRail(title: 'New Arrivals', products: products),
                loading: () => const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => _InlineSectionError(
                  height: 260,
                  onRetry: () => ref.invalidate(newArrivalsProvider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: trendingAsync.when(
                data: (products) =>
                    ProductRail(title: 'Trending Now', products: products),
                loading: () => const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => _InlineSectionError(
                  height: 260,
                  onRetry: () => ref.invalidate(trendingProvider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: recentlyViewedAsync.when(
                data: (products) =>
                    ProductRail(title: 'Recently Viewed', products: products),
                loading: () => const SizedBox.shrink(),
                // Recently-viewed needs a signed-in user — a guest 401 here
                // is expected, so this stays silent rather than alarming a
                // browsing (not logged-in) visitor.
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push(RoutePaths.notifications),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact inline retry affordance for a single home section — used instead
/// of hiding the section entirely, so a failed fetch never reads as "this
/// store has no products."
class _InlineSectionError extends StatelessWidget {
  const _InlineSectionError({required this.height, required this.onRetry});

  final double height;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load this section',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Search products, brands and more',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final Category category = categories[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(RoutePaths.categoryPath(category.slug)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: AppNetworkImage(url: category.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/presentation/cart_controller.dart';
import '../features/wishlist/presentation/wishlist_controller.dart';

/// Persistent bottom-nav shell around the 5 primary tabs. Each branch keeps
/// its own navigation stack and scroll position alive when switching tabs
/// (via [StatefulShellRoute.indexedStack]), which is what makes tab
/// switching feel instant rather than a full screen rebuild.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cartCount = ref.watch(cartItemCountProvider);
    final int wishlistCount = ref.watch(wishlistCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _badge(const Icon(Icons.favorite_border_rounded), wishlistCount),
            selectedIcon: _badge(const Icon(Icons.favorite_rounded), wishlistCount),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: _badge(const Icon(Icons.shopping_bag_outlined), cartCount),
            selectedIcon: _badge(const Icon(Icons.shopping_bag_rounded), cartCount),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _badge(Widget icon, int count) {
    if (count <= 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/catalog/presentation/category_products_screen.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/order_success_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/return_request_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/support/presentation/new_ticket_screen.dart';
import '../../features/support/presentation/support_tickets_screen.dart';
import '../../features/support/presentation/ticket_thread_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../../shared/main_shell.dart';
import 'route_paths.dart';
import 'router_notifier.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final RouterNotifier notifier = ref.watch(routerNotifierProvider);

  const List<String> publicOnlyRoutes = [
    RoutePaths.splash,
    RoutePaths.onboarding,
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.otp,
    RoutePaths.forgotPassword,
  ];
  const List<String> authRequiredPrefixes = [
    RoutePaths.cart,
    RoutePaths.checkout,
    RoutePaths.orders,
    RoutePaths.wishlist,
    RoutePaths.addresses,
    RoutePaths.profile,
    RoutePaths.wallet,
    RoutePaths.notifications,
    RoutePaths.support,
    '/order-success',
    '/returns',
  ];

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final AuthStatus status = notifier.status;
      final String location = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }
      if (location == RoutePaths.splash) {
        return status == AuthStatus.authenticated
            ? RoutePaths.home
            : RoutePaths.onboarding;
      }

      final bool isAuthenticated = status == AuthStatus.authenticated;
      if (isAuthenticated && publicOnlyRoutes.contains(location)) {
        return RoutePaths.home;
      }
      final bool requiresAuth =
          authRequiredPrefixes.any((prefix) => location.startsWith(prefix));
      if (!isAuthenticated && requiresAuth) {
        return RoutePaths.login;
      }
      return null;
    },
    routes: [
      GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const SplashScreen(),),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen(),),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.otp,
        builder: (context, state) => OtpScreen(
          identifier: state.uri.queryParameters['identifier'] ?? '',
          purpose: state.uri.queryParameters['purpose'] ?? 'login',
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.category,
        builder: (context, state) => CategoryProductsScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.product,
        builder: (context, state) => ProductDetailScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: RoutePaths.orderSuccess,
        builder: (context, state) => OrderSuccessScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.returns,
        builder: (context, state) => ReturnRequestScreen(
          orderItemId: state.pathParameters['orderItemId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: RoutePaths.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.support,
        builder: (context, state) => const SupportTicketsScreen(),
      ),
      GoRoute(
        path: RoutePaths.newSupportTicket,
        builder: (context, state) => const NewTicketScreen(),
      ),
      GoRoute(
        path: RoutePaths.ticketDetail,
        builder: (context, state) => TicketThreadScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: RoutePaths.home,
                  builder: (context, state) => const HomeScreen(),),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.wishlist,
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: RoutePaths.cart,
                  builder: (context, state) => const CartScreen(),),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

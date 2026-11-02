/// Central registry of route path strings — avoids typo-prone string
/// literals scattered across `context.go(...)` calls.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/';
  static const String search = '/search';
  static const String category = '/category/:slug';
  static const String product = '/product/:slug';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success/:orderId';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String addresses = '/addresses';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String returns = '/returns/:orderItemId';

  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String newSupportTicket = '/support/new';
  static const String ticketDetail = '/support/:ticketId';

  static String categoryPath(String slug) => '/category/$slug';
  static String productPath(String slug) => '/product/$slug';
  static String orderDetailPath(String orderId) => '/orders/$orderId';
  static String orderSuccessPath(String orderId) => '/order-success/$orderId';
  static String ticketDetailPath(String ticketId) => '/support/$ticketId';
}

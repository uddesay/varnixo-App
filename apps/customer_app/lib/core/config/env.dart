import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration loaded from `.env` (see `.env.example`).
/// Falls back to the Android emulator loopback address so a fresh checkout
/// works against a locally running backend without extra setup.
abstract final class Env {
  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:4200/api/v1';

  static String get socketUrl =>
      dotenv.maybeGet('SOCKET_URL') ?? 'http://10.0.2.2:4200';

  static String get googleWebClientId => dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ?? '';

  static String get razorpayKeyId => dotenv.maybeGet('RAZORPAY_KEY_ID') ?? '';

  static String get stripePublishableKey =>
      dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';
}

import 'package:flutter/material.dart';

/// Varnixo's forest, warm ivory, and lime palette.
abstract final class AppColors {
  static const Color primary = Color(0xFF344D36);
  static const Color primaryLight = Color(0xFF78916D);
  static const Color primaryDark = Color(0xFF203427);

  static const Color accent = Color(0xFFFF5A5F);
  static const Color accentLight = Color(0xFFFF8A8E);

  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE0245E);
  static const Color info = Color(0xFF2196F3);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFFCFBF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3E9);
  static const Color lightOutline = Color(0xFFE3E1EC);
  static const Color lightOnSurface = Color(0xFF1B1B23);
  static const Color lightOnSurfaceMuted = Color(0xFF6F6D7A);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF121016);
  static const Color darkSurface = Color(0xFF1C1A24);
  static const Color darkSurfaceVariant = Color(0xFF272531);
  static const Color darkOutline = Color(0xFF3A3846);
  static const Color darkOnSurface = Color(0xFFF2F1F7);
  static const Color darkOnSurfaceMuted = Color(0xFFA6A3B3);

  // Semantic — ratings & pricing
  static const Color ratingStar = Color(0xFFFFB300);
  static const Color priceStrike = Color(0xFF9C9AA8);
  static const Color discountBadge = Color(0xFF1DB954);

  /// Glassmorphism overlay tint used behind app bars / bottom sheets.
  static Color glass(Brightness brightness) =>
      (brightness == Brightness.dark ? Colors.black : Colors.white)
          .withOpacity(0.55);
}

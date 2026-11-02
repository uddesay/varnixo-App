import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized type ramp built on Poppins. Kept as a plain [TextTheme]
/// factory so light/dark themes derive identical metrics and only diverge
/// on color (applied by [ThemeData.textTheme] via `.apply`).
abstract final class AppTextStyles {
  static TextTheme textTheme(Color baseColor) {
    final TextTheme base = GoogleFonts.poppinsTextTheme();
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: baseColor, displayColor: baseColor);
  }
}

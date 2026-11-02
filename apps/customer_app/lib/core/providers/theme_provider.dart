import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'app_theme_mode';

/// Persisted light/dark/system preference — read synchronously at startup
/// via [ThemeModeNotifier.bootstrap] so the correct theme applies before
/// first frame (no flash of the wrong theme).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_themeModeKey);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

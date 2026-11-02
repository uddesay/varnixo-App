import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';

class VarnixoApp extends ConsumerWidget {
  const VarnixoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    // Instantiates AuthController eagerly so it bootstraps the session and
    // starts listening for forced-logout events immediately at app start,
    // rather than lazily on first read from some deep screen.
    ref.watch(authControllerProvider);

    return MaterialApp.router(
      title: 'Varnixo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

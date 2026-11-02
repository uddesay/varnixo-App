import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// Purely presentational — the router's redirect logic (driven by
/// [AuthController.bootstrap]) moves the app past this screen automatically
/// once the session status resolves, so there is no navigation code here.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 72,
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text(
              'Varnixo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

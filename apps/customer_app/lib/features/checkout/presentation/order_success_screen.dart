import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Order placed successfully!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll notify you as your order is packed and shipped.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Track order',
                onPressed: () => context.go(RoutePaths.orderDetailPath(orderId)),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Continue shopping',
                outlined: true,
                onPressed: () => context.go(RoutePaths.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

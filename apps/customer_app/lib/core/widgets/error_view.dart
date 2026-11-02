import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import 'primary_button.dart';

/// Renders any thrown error as a retry-able full-page state. Used as the
/// `error` branch of `AsyncValue.when(...)` across feature screens.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  String get _message =>
      error is ApiException ? (error as ApiException).message : 'Something went wrong.';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

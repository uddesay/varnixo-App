import 'package:flutter/material.dart';

/// Full-width pill button with a built-in loading spinner state, used for
/// every primary CTA (login, add to cart, place order) so the disabled/busy
/// treatment is consistent across the app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    if (outlined) {
      return OutlinedButton(onPressed: effectiveOnPressed, child: child);
    }
    return ElevatedButton(onPressed: effectiveOnPressed, child: child);
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact "4.3 ★ (1.2k)" pill used on product cards and vendor headers.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.rating,
    super.key,
    this.count,
    this.small = false,
  });

  final double rating;
  final int? count;
  final bool small;

  String _formatCount(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: small ? 11 : 12,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.star_rounded, color: AppColors.success, size: small ? 11 : 13),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${_formatCount(count!)})',
              style: TextStyle(
                color: AppColors.success,
                fontSize: small ? 10 : 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

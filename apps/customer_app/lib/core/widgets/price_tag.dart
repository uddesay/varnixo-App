import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Sale price + struck-through MRP + discount percentage badge, the
/// standard price presentation used on product cards and the PDP.
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.priceMinor,
    super.key,
    this.mrpMinor,
    this.priceStyle,
    this.compact = false,
  });

  final int priceMinor;
  final int? mrpMinor;
  final TextStyle? priceStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final int? mrp = mrpMinor;
    final bool hasDiscount = mrp != null && mrp > priceMinor;
    final int discountPercent = hasDiscount
        ? CurrencyFormatter.discountPercent(mrpMinor: mrp, priceMinor: priceMinor)
        : 0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          CurrencyFormatter.format(priceMinor),
          style: priceStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
        ),
        if (hasDiscount)
          Text(
            CurrencyFormatter.format(mrp),
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: AppColors.priceStrike,
              fontSize: compact ? 12 : 13,
            ),
          ),
        if (hasDiscount && discountPercent > 0)
          Text(
            '$discountPercent% OFF',
            style: TextStyle(
              color: AppColors.discountBadge,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 13,
            ),
          ),
      ],
    );
  }
}

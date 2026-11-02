import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OrderStatusInfo {
  const OrderStatusInfo(this.label, this.color);
  final String label;
  final Color color;
}

OrderStatusInfo orderStatusInfo(String status) {
  switch (status) {
    case 'pending_payment':
      return const OrderStatusInfo('Payment Pending', AppColors.warning);
    case 'confirmed':
      return const OrderStatusInfo('Confirmed', AppColors.info);
    case 'processing':
      return const OrderStatusInfo('Processing', AppColors.info);
    case 'packed':
      return const OrderStatusInfo('Packed', AppColors.info);
    case 'shipped':
      return const OrderStatusInfo('Shipped', AppColors.primary);
    case 'out_for_delivery':
      return const OrderStatusInfo('Out for Delivery', AppColors.primary);
    case 'delivered':
      return const OrderStatusInfo('Delivered', AppColors.success);
    case 'cancelled':
      return const OrderStatusInfo('Cancelled', AppColors.error);
    case 'returned':
      return const OrderStatusInfo('Returned', AppColors.error);
    case 'refunded':
      return const OrderStatusInfo('Refunded', AppColors.success);
    case 'payment_failed':
      return const OrderStatusInfo('Payment Failed', AppColors.error);
    default:
      return OrderStatusInfo(status, AppColors.info);
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final info = orderStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.label,
        style: TextStyle(color: info.color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/network_image.dart';
import '../domain/order.dart';
import 'order_providers.dart';
import 'widgets/order_status_chip.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(orderListProvider),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorView(error: error, onRetry: () => ref.invalidate(orderListProvider)),
          data: (orders) {
            if (orders.isEmpty) {
              return EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your order history will show up here.',
                actionLabel: 'Start shopping',
                onAction: () => context.go(RoutePaths.home),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(RoutePaths.orderDetailPath(order.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.placedAt.day}/${order.placedAt.month}/${order.placedAt.year}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => SizedBox(
                    width: 56,
                    child: AppNetworkImage(
                      url: order.items[index].image,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                CurrencyFormatter.format(order.totalMinor),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

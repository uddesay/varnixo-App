import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/network_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/order.dart';
import 'order_providers.dart';
import 'widgets/order_status_chip.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  Future<void> _downloadInvoice(BuildContext context, WidgetRef ref) async {
    try {
      final bytes =
          await ref.read(orderRepositoryProvider).downloadInvoice(orderId);
      await Share.shareXFiles(
        [
          XFile.fromData(Uint8List.fromList(bytes),
              mimeType: 'application/pdf', name: 'invoice.pdf',),
        ],
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download invoice')),);
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelReasonDialog(),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref.read(orderRepositoryProvider).cancel(orderId, reason);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(orderListProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not cancel this order')),);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            onPressed: () => _downloadInvoice(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.orderNumber}',
                    style: Theme.of(context).textTheme.titleMedium,),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 20),
            if (order.statusHistory.isNotEmpty)
              _StatusTimeline(events: order.statusHistory),
            const SizedBox(height: 24),
            if (order.shipments.isNotEmpty) ...[
              Text('Shipments', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...order.shipments.map((s) => _ShipmentTile(shipment: s)),
              const SizedBox(height: 20),
            ],
            Text('Items', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...order.items.map((item) =>
                _OrderItemTile(item: item, orderStatus: order.status),),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Subtotal',
                        CurrencyFormatter.format(order.subtotalMinor),),
                    if (order.discountMinor > 0)
                      _row('Discount',
                          '-${CurrencyFormatter.format(order.discountMinor)}',),
                    _row(
                      'Shipping',
                      order.shippingMinor == 0
                          ? 'FREE'
                          : CurrencyFormatter.format(order.shippingMinor),
                    ),
                    const Divider(height: 20),
                    _row('Total', CurrencyFormatter.format(order.totalMinor),
                        bold: true,),
                  ],
                ),
              ),
            ),
            if (order.isCancellable) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Cancel Order',
                outlined: true,
                onPressed: () => _cancelOrder(context, ref),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontSize: bold ? 16 : 14,);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.events});
  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final bool isLast = entry.key == events.length - 1;
        final info = orderStatusInfo(entry.value.toStatus);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: info.color, shape: BoxShape.circle,),),
                  if (!isLast)
                    Expanded(
                        child: Container(
                            width: 2,
                            color: Theme.of(context).colorScheme.outline,),),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),),
                      Text(
                        '${entry.value.createdAt.day}/${entry.value.createdAt.month}/${entry.value.createdAt.year} '
                        '${entry.value.createdAt.hour.toString().padLeft(2, '0')}:${entry.value.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShipmentTile extends StatelessWidget {
  const _ShipmentTile({required this.shipment});
  final OrderShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(shipment.vendorName ?? 'Seller'),
        subtitle: shipment.awbNumber != null
            ? Text(
                '${shipment.courier?.toUpperCase() ?? ''} · AWB ${shipment.awbNumber}',)
            : null,
        trailing: OrderStatusChip(status: shipment.status),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item, required this.orderStatus});
  final OrderItemDetail item;
  final String orderStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: AppNetworkImage(
                  url: item.imageUrl, borderRadius: BorderRadius.circular(8),),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,),
                  Text(
                    'Qty ${item.quantity} · ${CurrencyFormatter.format(item.unitPriceMinor)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,),
                  ),
                ],
              ),
            ),
            if (orderStatus == 'delivered')
              TextButton(
                onPressed: () => context.push('/returns/${item.id}'),
                child: const Text('Return'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel order'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Reason for cancellation'),
        maxLines: 2,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

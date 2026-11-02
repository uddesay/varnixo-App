import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

final Provider<OrderRepository> orderRepositoryProvider =
    Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);

final FutureProvider<List<OrderSummary>> orderListProvider =
    FutureProvider<List<OrderSummary>>((ref) async {
  final result = await ref.watch(orderRepositoryProvider).list();
  return result.items;
});

final orderDetailProvider = FutureProvider.family<OrderDetail, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).getDetail(orderId),
);

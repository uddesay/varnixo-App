import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/order.dart';

class OrderRepository {
  OrderRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResult<OrderSummary>> list({int page = 1}) async {
    final envelope = await _client.getEnvelope('/orders', queryParameters: {'page': page, 'limit': 10});
    return PaginatedResult.fromEnvelope(envelope, OrderSummary.fromJson);
  }

  Future<OrderDetail> getDetail(String orderId) async {
    final data = await _client.get('/orders/$orderId');
    return OrderDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cancel(String orderId, String reason) =>
      _client.post('/orders/$orderId/cancel', data: {'reason': reason});

  Future<List<int>> downloadInvoice(String orderId) => _client.download('/orders/$orderId/invoice');

  Future<void> createReturnRequest({
    required String orderItemId,
    required String requestType,
    required String reason,
    String? description,
    int quantity = 1,
  }) =>
      _client.post('/returns', data: {
        'orderItemId': orderItemId,
        'requestType': requestType,
        'reason': reason,
        if (description != null && description.isNotEmpty) 'description': description,
        'quantity': quantity,
      },);
}

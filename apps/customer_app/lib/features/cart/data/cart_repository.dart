import '../../../core/network/api_client.dart';
import '../domain/cart.dart';

class CartRepository {
  CartRepository(this._client);

  final ApiClient _client;

  Future<Cart> getCart() async {
    final data = await _client.get('/cart');
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  /// "Buy Now" totals preview for a single variant — read-only, never
  /// touches the persisted cart.
  Future<Cart> previewBuyNow({required String variantId, required int quantity}) async {
    final data = await _client.get('/cart/preview', queryParameters: {
      'variantId': variantId,
      'quantity': quantity,
    },);
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> addItem({required String variantId, int quantity = 1}) async {
    final data = await _client.post('/cart/items', data: {
      'variantId': variantId,
      'quantity': quantity,
    },);
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> updateItem(String itemId, {int? quantity, bool? saveForLater}) async {
    final data = await _client.patch('/cart/items/$itemId', data: {
      if (quantity != null) 'quantity': quantity,
      if (saveForLater != null) 'saveForLater': saveForLater,
    },);
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> removeItem(String itemId) async {
    final data = await _client.delete('/cart/items/$itemId');
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> applyCoupon(String code) async {
    final data = await _client.post('/cart/coupon', data: {'code': code});
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> removeCoupon() async {
    final data = await _client.delete('/cart/coupon');
    return Cart.fromJson(data as Map<String, dynamic>);
  }
}

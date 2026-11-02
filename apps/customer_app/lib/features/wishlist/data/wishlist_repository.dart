import '../../../core/network/api_client.dart';
import '../../catalog/domain/product_card.dart';

class WishlistItem {
  const WishlistItem({required this.addedAt, required this.product});

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
        product: ProductCard.fromJson(json['product'] as Map<String, dynamic>),
      );

  final DateTime addedAt;
  final ProductCard product;
}

class WishlistRepository {
  WishlistRepository(this._client);

  final ApiClient _client;

  Future<List<WishlistItem>> list() async {
    final data = await _client.get('/wishlist');
    return (data as List<dynamic>)
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String productId) =>
      _client.post('/wishlist/items', data: {'productId': productId});

  Future<void> remove(String productId) => _client.delete('/wishlist/items/$productId');
}

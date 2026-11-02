import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/category.dart';
import '../domain/product_card.dart';
import '../domain/product_detail.dart';

class ProductListParams {
  const ProductListParams({
    this.page = 1,
    this.limit = 20,
    this.category,
    this.brand,
    this.priceMin,
    this.priceMax,
    this.rating,
    this.sort = 'newest',
  });

  final int page;
  final int limit;
  final String? category;
  final String? brand;
  final int? priceMin;
  final int? priceMax;
  final double? rating;
  final String sort;

  Map<String, dynamic> toQuery() => {
        'page': page,
        'limit': limit,
        'sort': sort,
        if (category != null) 'category': category,
        if (brand != null) 'brand': brand,
        if (priceMin != null) 'priceMin': priceMin,
        if (priceMax != null) 'priceMax': priceMax,
        if (rating != null) 'rating': rating,
      };

  ProductListParams copyWith({int? page, String? sort, int? priceMin, int? priceMax, double? rating}) =>
      ProductListParams(
        page: page ?? this.page,
        limit: limit,
        category: category,
        brand: brand,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        rating: rating ?? this.rating,
        sort: sort ?? this.sort,
      );
}

class CatalogRepository {
  CatalogRepository(this._client);

  final ApiClient _client;

  Future<List<Category>> getCategoryTree() async {
    final data = await _client.get('/categories');
    return (data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<ProductCard>> listProducts(ProductListParams params) async {
    final envelope = await _client.getEnvelope('/products', queryParameters: params.toQuery());
    return PaginatedResult.fromEnvelope(envelope, ProductCard.fromJson);
  }

  Future<ProductDetail> getProductBySlug(String slug) async {
    final data = await _client.get('/products/$slug');
    return ProductDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProductCard>> getRelatedProducts(String slug) async {
    final data = await _client.get('/products/$slug/related');
    return (data as List<dynamic>)
        .map((e) => ProductCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<ProductCard>> search({
    required String query,
    int page = 1,
    String? category,
    String sort = 'relevance',
  }) async {
    final envelope = await _client.getEnvelope('/search', queryParameters: {
      'q': query,
      'page': page,
      'sort': sort,
      if (category != null) 'category': category,
    },);
    final Map<String, dynamic> data = envelope['data'] as Map<String, dynamic>;
    final List<dynamic> rows = data['rows'] as List<dynamic>? ?? [];
    return PaginatedResult(
      items: rows.map((e) => ProductCard.fromJson(e as Map<String, dynamic>)).toList(),
      page: (envelope['meta'] as Map<String, dynamic>?)?['page'] as int? ?? 1,
      totalPages:
          (envelope['meta'] as Map<String, dynamic>?)?['totalPages'] as int? ?? 1,
      total: (envelope['meta'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> suggest(String query) async {
    final data = await _client.get('/search/suggest', queryParameters: {'q': query});
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> trackRecentlyViewed(String productId) =>
      _client.post('/recently-viewed', data: {'productId': productId});

  Future<List<ProductCard>> getRecentlyViewed() async {
    final data = await _client.get('/recently-viewed');
    return (data as List<dynamic>)
        .map((e) => ProductCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

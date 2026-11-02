/// Product summary as returned by the public listing endpoints
/// (`GET /products`, `/search`, related products, wishlist, recently viewed).
class ProductCard {
  const ProductCard({
    required this.id,
    required this.title,
    required this.slug,
    required this.priceMinor,
    this.mrpMinor,
    this.imageUrl,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isCodAvailable = true,
  });

  factory ProductCard.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? image = json['image'] as Map<String, dynamic>?;
    return ProductCard(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      priceMinor: _asInt(json['min_price'] ?? json['price_minor'] ?? json['priceMinor']),
      mrpMinor: _asIntOrNull(json['min_mrp'] ?? json['mrp_minor'] ?? json['mrpMinor']),
      imageUrl: image?['thumbnail_url'] as String? ??
          image?['url'] as String? ??
          json['image_url'] as String?,
      ratingAvg: double.tryParse('${json['rating_avg'] ?? 0}') ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      isCodAvailable: json['is_cod_available'] as bool? ?? true,
    );
  }

  final String id;
  final String title;
  final String slug;
  final int priceMinor;
  final int? mrpMinor;
  final String? imageUrl;
  final double ratingAvg;
  final int ratingCount;
  final bool isCodAvailable;
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  return value is int ? value : int.tryParse('$value');
}

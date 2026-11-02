class ProductVariantOption {
  const ProductVariantOption({required this.name, required this.value});

  factory ProductVariantOption.fromJson(Map<String, dynamic> json) =>
      ProductVariantOption(
        name: json['name'] as String? ?? json['option_name'] as String,
        value: json['value'] as String? ?? json['option_value'] as String,
      );

  final String name;
  final String value;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.mrpMinor,
    required this.salePriceMinor,
    required this.options,
    this.availableStock = 0,
    this.inStock = false,
    this.isDefault = false,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'] as String,
        sku: json['sku'] as String,
        mrpMinor: json['mrp_minor'] as int,
        salePriceMinor: json['sale_price_minor'] as int,
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => ProductVariantOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        availableStock: json['available_stock'] as int? ?? 0,
        inStock: json['in_stock'] as bool? ?? false,
        isDefault: json['is_default'] as bool? ?? false,
      );

  final String id;
  final String sku;
  final int mrpMinor;
  final int salePriceMinor;
  final List<ProductVariantOption> options;
  final int availableStock;
  final bool inStock;
  final bool isDefault;

  String? optionValue(String name) =>
      options.where((o) => o.name == name).map((o) => o.value).firstOrNull;
}

class ProductMedia {
  const ProductMedia({required this.url, this.thumbnailUrl, this.mediaType = 'image'});

  factory ProductMedia.fromJson(Map<String, dynamic> json) => ProductMedia(
        url: json['url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        mediaType: json['media_type'] as String? ?? 'image',
      );

  final String url;
  final String? thumbnailUrl;
  final String mediaType;
}

class ProductSpecification {
  const ProductSpecification({
    required this.group,
    required this.key,
    required this.value,
  });

  factory ProductSpecification.fromJson(Map<String, dynamic> json) => ProductSpecification(
        group: json['group_name'] as String? ?? 'General',
        key: json['spec_key'] as String,
        value: json['spec_value'] as String,
      );

  final String group;
  final String key;
  final String value;
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.variants,
    required this.media,
    required this.specifications,
    this.highlights = const [],
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.isReturnable = true,
    this.returnWindowDays = 7,
    this.isCodAvailable = true,
    this.categoryName,
    this.brandName,
    this.vendorId,
    this.vendorName,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        highlights: (json['highlights'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        variants: (json['variants'] as List<dynamic>? ?? [])
            .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
            .toList(),
        media: (json['media'] as List<dynamic>? ?? [])
            .map((e) => ProductMedia.fromJson(e as Map<String, dynamic>))
            .toList(),
        specifications: (json['specifications'] as List<dynamic>? ?? [])
            .map((e) => ProductSpecification.fromJson(e as Map<String, dynamic>))
            .toList(),
        ratingAvg: double.tryParse('${json['rating_avg'] ?? 0}') ?? 0,
        ratingCount: json['rating_count'] as int? ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        isReturnable: json['is_returnable'] as bool? ?? true,
        returnWindowDays: json['return_window_days'] as int? ?? 7,
        isCodAvailable: json['is_cod_available'] as bool? ?? true,
        categoryName: json['category_name'] as String?,
        brandName: json['brand_name'] as String?,
        vendorId: json['vendor_id'] as String?,
        vendorName: json['vendor_name'] as String?,
      );

  final String id;
  final String title;
  final String slug;
  final String description;
  final List<String> highlights;
  final List<ProductVariant> variants;
  final List<ProductMedia> media;
  final List<ProductSpecification> specifications;
  final double ratingAvg;
  final int ratingCount;
  final int reviewCount;
  final bool isReturnable;
  final int returnWindowDays;
  final bool isCodAvailable;
  final String? categoryName;
  final String? brandName;
  final String? vendorId;
  final String? vendorName;

  ProductVariant get defaultVariant =>
      variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);

  List<String> get optionNames =>
      variants.expand((v) => v.options.map((o) => o.name)).toSet().toList();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

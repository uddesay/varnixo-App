class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.iconUrl,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        imageUrl: json['image_url'] as String?,
        iconUrl: json['icon_url'] as String?,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? iconUrl;
  final List<Category> children;
}

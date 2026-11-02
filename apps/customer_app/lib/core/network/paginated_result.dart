/// Wraps a page of results plus the backend's `meta` pagination block.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  factory PaginatedResult.fromEnvelope(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> data = envelope['data'] as List<dynamic>? ?? [];
    final Map<String, dynamic>? meta = envelope['meta'] as Map<String, dynamic>?;
    return PaginatedResult(
      items: data.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: meta?['page'] as int? ?? 1,
      totalPages: meta?['totalPages'] as int? ?? 1,
      total: meta?['total'] as int? ?? data.length,
    );
  }

  final List<T> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

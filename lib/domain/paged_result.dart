class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromJson,
  ) {
    final rawItems = json['items'];
    return PagedResult<T>(
      items: rawItems is List
          ? rawItems
              .cast<Map<dynamic, dynamic>>()
              .map((item) => fromJson(item.cast<String, dynamic>()))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

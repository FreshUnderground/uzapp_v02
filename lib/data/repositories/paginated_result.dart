class PaginatedResult<T> {
  final List<T> data;
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });
}

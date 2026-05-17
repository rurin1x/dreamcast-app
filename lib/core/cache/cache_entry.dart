final class CachedValue<T> {
  const CachedValue({
    required this.value,
    required this.updatedAt,
    required this.isStale,
  });

  final T value;
  final DateTime updatedAt;
  final bool isStale;
}

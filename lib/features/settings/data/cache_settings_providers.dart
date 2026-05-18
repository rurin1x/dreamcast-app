import 'package:dream_cast/core/cache/cache_repository.dart';
import 'package:dream_cast/core/cache/cache_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cacheStatsProvider = FutureProvider<CacheStats>((ref) {
  return ref.watch(cacheRepositoryProvider).stats();
});

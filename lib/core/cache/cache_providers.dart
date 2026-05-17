import 'package:dream_cast/core/cache/cache_repository.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cacheRepositoryProvider = Provider<CacheRepository>(
  (ref) => CacheRepository(ref.watch(appDatabaseProvider)),
);

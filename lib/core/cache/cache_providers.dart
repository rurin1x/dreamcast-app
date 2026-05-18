import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/core/cache/cache_retention.dart';
import 'package:dream_cast/core/cache/cache_repository.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cacheRetentionProvider =
    NotifierProvider<CacheRetentionController, CacheRetentionOption>(
      CacheRetentionController.new,
    );

final cacheRepositoryProvider = Provider<CacheRepository>(
  (ref) => CacheRepository(
    ref.watch(appDatabaseProvider),
    retention: ref.watch(cacheRetentionProvider),
  ),
);

final class CacheRetentionController extends Notifier<CacheRetentionOption> {
  static const _key = 'cache.retention';

  @override
  CacheRetentionOption build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return CacheRetentionOption.values.firstWhere(
      (value) => value.name == name,
      orElse: () => CacheRetentionOption.hours8,
    );
  }

  Future<void> setRetention(CacheRetentionOption value) async {
    await ref.read(sharedPreferencesProvider).setString(_key, value.name);
    state = value;
  }
}

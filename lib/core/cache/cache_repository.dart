import 'dart:convert';

import 'package:dream_cast/core/cache/cache_entry.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:drift/drift.dart';

final class CacheRepository {
  const CacheRepository(this._database);

  final AppDatabase _database;

  Future<void> putJson(
    String key,
    Object value, {
    Duration? ttl,
    String? etag,
  }) {
    final now = DateTime.now();
    return _database.putCacheEntry(
      CacheEntriesCompanion(
        key: Value(key),
        valueJson: Value(jsonEncode(value)),
        updatedAt: Value(now),
        expiresAt: Value(ttl == null ? null : now.add(ttl)),
        etag: Value(etag),
      ),
    );
  }

  Future<CachedValue<Map<String, Object?>>?> getJsonMap(String key) async {
    final row = await _database.cacheEntry(key);
    if (row == null) return null;

    final decoded = jsonDecode(row.valueJson);
    if (decoded is! Map) return null;

    final expiresAt = row.expiresAt;
    return CachedValue<Map<String, Object?>>(
      value: decoded.cast<String, Object?>(),
      updatedAt: row.updatedAt,
      isStale: expiresAt != null && DateTime.now().isAfter(expiresAt),
    );
  }

  Future<int> clearExpired() => _database.clearExpiredCache(DateTime.now());
}

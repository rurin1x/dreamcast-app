import 'dart:convert';

import 'package:dream_cast/core/cache/cache_entry.dart';
import 'package:dream_cast/core/cache/cache_retention.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:drift/drift.dart';

final class CacheStats {
  const CacheStats({
    required this.entriesCount,
    required this.approximateBytes,
    required this.maxRetention,
  });

  final int entriesCount;
  final int approximateBytes;
  final Duration? maxRetention;
}

final class CacheRepository {
  const CacheRepository(
    this._database, {
    required CacheRetentionOption retention,
  }) : _retention = retention;

  final AppDatabase _database;
  final CacheRetentionOption _retention;

  Future<void> putJson(
    String key,
    Object value, {
    Duration? ttl,
    String? etag,
  }) {
    final now = DateTime.now();
    final expiresAt = _expiresAt(now, ttl);
    return _database.putCacheEntry(
      CacheEntriesCompanion(
        key: Value(key),
        valueJson: Value(jsonEncode(value)),
        updatedAt: Value(now),
        expiresAt: Value(expiresAt),
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

  Future<int> clearAll() => _database.clearAllCache();

  Future<int> applyCurrentRetentionToExistingEntries() {
    return _database.rewriteCacheExpiration(_retention.duration);
  }

  Future<CacheStats> stats() async {
    final entries = await _database.allCacheEntries();
    var bytes = 0;
    Duration? maxRetention;

    for (final entry in entries) {
      bytes += utf8.encode(entry.key).length;
      bytes += utf8.encode(entry.valueJson).length;
      bytes += utf8.encode(entry.etag ?? '').length;

      final expiresAt = entry.expiresAt;
      if (expiresAt != null && expiresAt.isAfter(entry.updatedAt)) {
        final retention = expiresAt.difference(entry.updatedAt);
        if (maxRetention == null || retention > maxRetention) {
          maxRetention = retention;
        }
      }
    }

    return CacheStats(
      entriesCount: entries.length,
      approximateBytes: bytes,
      maxRetention: maxRetention,
    );
  }

  DateTime? _expiresAt(DateTime now, Duration? ttl) {
    if (_retention == CacheRetentionOption.forever) return null;
    final duration = _retention.duration ?? ttl;
    return duration == null ? null : now.add(duration);
  }
}

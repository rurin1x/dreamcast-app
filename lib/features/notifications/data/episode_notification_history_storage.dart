import 'dart:convert';

import 'package:dream_cast/features/notifications/data/episode_notification_history.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class EpisodeNotificationHistoryStorage {
  const EpisodeNotificationHistoryStorage._();

  static const itemPrefix = 'notifications.history.item.';
  static const pendingTapKey = 'notifications.pending_tap_id';

  static List<EpisodeNotificationHistoryEntry> readAll(
    SharedPreferences preferences,
  ) {
    final entries = <EpisodeNotificationHistoryEntry>[];
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(itemPrefix)) continue;
      final raw = preferences.getString(key);
      if (raw == null) continue;
      final entry = _entryFromJson(raw);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static EpisodeNotificationHistoryEntry? read(
    SharedPreferences preferences,
    String id,
  ) {
    final raw = preferences.getString('$itemPrefix$id');
    return raw == null ? null : _entryFromJson(raw);
  }

  static Future<void> save(
    SharedPreferences preferences,
    EpisodeNotificationHistoryEntry entry,
  ) {
    return preferences.setString(
      '$itemPrefix${entry.id}',
      jsonEncode(_entryToJson(entry)),
    );
  }

  static Future<void> markRead(SharedPreferences preferences, String id) async {
    final entry = read(preferences, id);
    if (entry == null || entry.isRead) return;
    await save(preferences, entry.copyWith(readAt: DateTime.now()));
  }

  static Future<void> markAllRead(SharedPreferences preferences) async {
    final now = DateTime.now();
    for (final entry in readAll(preferences)) {
      if (!entry.isRead) {
        await save(preferences, entry.copyWith(readAt: now));
      }
    }
  }

  static Future<void> clearAll(SharedPreferences preferences) async {
    for (final key in preferences.getKeys().toList()) {
      if (key.startsWith(itemPrefix)) await preferences.remove(key);
    }
  }

  static int unreadCount(SharedPreferences preferences) {
    return readAll(preferences).where((entry) => !entry.isRead).length;
  }

  static Future<void> setPendingTap(SharedPreferences preferences, String id) {
    return preferences.setString(pendingTapKey, id);
  }

  static Future<String?> consumePendingTap(
    SharedPreferences preferences,
  ) async {
    final id = preferences.getString(pendingTapKey);
    if (id != null) await preferences.remove(pendingTapKey);
    return id;
  }
}

EpisodeNotificationHistoryEntry? _entryFromJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return null;
  final releaseRaw = decoded['release'];
  if (releaseRaw is! Map) return null;
  return EpisodeNotificationHistoryEntry(
    id: decoded['id'] as String? ?? '',
    release: _releaseFromJson(releaseRaw.cast<String, Object?>()),
    message: decoded['message'] as String? ?? '',
    previousCount: (decoded['previousCount'] as num?)?.toInt() ?? 0,
    currentCount: (decoded['currentCount'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(decoded['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    readAt: DateTime.tryParse(decoded['readAt'] as String? ?? ''),
  );
}

Map<String, Object?> _entryToJson(EpisodeNotificationHistoryEntry entry) => {
  'id': entry.id,
  'release': _releaseToJson(entry.release),
  'message': entry.message,
  'previousCount': entry.previousCount,
  'currentCount': entry.currentCount,
  'createdAt': entry.createdAt.toIso8601String(),
  'readAt': entry.readAt?.toIso8601String(),
};

Map<String, Object?> _releaseToJson(DreamRelease release) => {
  'id': release.id,
  'title': release.title,
  'originalTitle': release.originalTitle,
  'url': release.url,
  'posterUrl': release.posterUrl,
  'wallUrl': release.wallUrl,
  'description': release.description,
  'status': release.status,
  'type': release.type,
  'year': release.year,
  'season': release.season,
  'genres': release.genres,
  'studio': release.studio,
  'durationMinutes': release.durationMinutes,
  'totalEpisodes': release.totalEpisodes,
  'currentEpisodes': release.currentEpisodes,
  'rating': release.rating,
  'raw': release.raw,
};

DreamRelease _releaseFromJson(Map<String, Object?> json) {
  return DreamRelease(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    originalTitle: json['originalTitle'] as String? ?? '',
    url: json['url'] as String? ?? '',
    posterUrl: json['posterUrl'] as String?,
    wallUrl: json['wallUrl'] as String?,
    description: json['description'] as String?,
    status: json['status'] as String?,
    type: json['type'] as String?,
    year: (json['year'] as num?)?.toInt(),
    season: json['season'] as String?,
    genres: json['genres'] as String?,
    studio: json['studio'] as String?,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    totalEpisodes: (json['totalEpisodes'] as num?)?.toInt(),
    currentEpisodes: (json['currentEpisodes'] as num?)?.toInt(),
    rating: json['rating'] as String?,
    raw: (json['raw'] as Map?)?.cast<String, Object?>() ?? const {},
  );
}

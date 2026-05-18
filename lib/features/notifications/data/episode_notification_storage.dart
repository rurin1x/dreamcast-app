import 'dart:convert';

import 'package:dream_cast/features/notifications/data/episode_notification_subscription.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class EpisodeNotificationStorage {
  const EpisodeNotificationStorage._();

  static const itemPrefix = 'notifications.release.item.';

  static bool isSubscribed(SharedPreferences preferences, int releaseId) {
    return preferences.containsKey('$itemPrefix$releaseId');
  }

  static EpisodeNotificationSubscription? read(
    SharedPreferences preferences,
    int releaseId,
  ) {
    final raw = preferences.getString('$itemPrefix$releaseId');
    return raw == null ? null : _subscriptionFromJson(raw);
  }

  static List<EpisodeNotificationSubscription> readAll(
    SharedPreferences preferences,
  ) {
    final subscriptions = <EpisodeNotificationSubscription>[];
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(itemPrefix)) continue;
      final raw = preferences.getString(key);
      if (raw == null) continue;
      final subscription = _subscriptionFromJson(raw);
      if (subscription != null) subscriptions.add(subscription);
    }
    subscriptions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return subscriptions;
  }

  static Future<void> save(
    SharedPreferences preferences,
    EpisodeNotificationSubscription subscription,
  ) {
    return preferences.setString(
      '$itemPrefix${subscription.release.id}',
      jsonEncode(_subscriptionToJson(subscription)),
    );
  }

  static Future<void> remove(SharedPreferences preferences, int releaseId) {
    return preferences.remove('$itemPrefix$releaseId');
  }
}

EpisodeNotificationSubscription? _subscriptionFromJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return null;
  final releaseRaw = decoded['release'];
  if (releaseRaw is! Map) return null;
  return EpisodeNotificationSubscription(
    release: _releaseFromJson(releaseRaw.cast<String, Object?>()),
    lastKnownEpisodes: (decoded['lastKnownEpisodes'] as num?)?.toInt() ?? 0,
    updatedAt:
        DateTime.tryParse(decoded['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Map<String, Object?> _subscriptionToJson(
  EpisodeNotificationSubscription subscription,
) {
  return {
    'release': _releaseToJson(subscription.release),
    'lastKnownEpisodes': subscription.lastKnownEpisodes,
    'updatedAt': subscription.updatedAt.toIso8601String(),
  };
}

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

import 'dart:convert';

import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReleaseBookmarkStatus { watching, completed, dropped, planned }

extension ReleaseBookmarkStatusLabel on ReleaseBookmarkStatus {
  String get label {
    return switch (this) {
      ReleaseBookmarkStatus.watching => 'Смотрю',
      ReleaseBookmarkStatus.completed => 'Просмотрено',
      ReleaseBookmarkStatus.dropped => 'Брошено',
      ReleaseBookmarkStatus.planned => 'В планах',
    };
  }
}

final releaseBookmarkProvider =
    NotifierProvider.family<
      ReleaseBookmarkController,
      ReleaseBookmarkStatus?,
      int
    >(ReleaseBookmarkController.new);

final libraryBookmarksProvider =
    NotifierProvider<LibraryBookmarksController, List<ReleaseBookmarkEntry>>(
      LibraryBookmarksController.new,
    );

final class ReleaseBookmarkEntry {
  const ReleaseBookmarkEntry({
    required this.status,
    required this.release,
    required this.updatedAt,
  });

  final ReleaseBookmarkStatus status;
  final DreamRelease release;
  final DateTime updatedAt;
}

final class LibraryBookmarksController
    extends Notifier<List<ReleaseBookmarkEntry>> {
  @override
  List<ReleaseBookmarkEntry> build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final entries = <ReleaseBookmarkEntry>[];

    for (final key in preferences.getKeys()) {
      if (!key.startsWith(ReleaseBookmarkController.itemPrefix)) continue;
      final raw = preferences.getString(key);
      if (raw == null) continue;
      final entry = _entryFromJson(raw);
      if (entry != null) entries.add(entry);
    }

    entries.sort((a, b) {
      final byDate = b.updatedAt.compareTo(a.updatedAt);
      if (byDate != 0) return byDate;
      return a.release.title.compareTo(b.release.title);
    });
    return entries;
  }
}

final class ReleaseBookmarkController extends Notifier<ReleaseBookmarkStatus?> {
  ReleaseBookmarkController(this._releaseId);

  static const _prefix = 'library.release.status.';
  static const itemPrefix = 'library.release.item.';
  final int _releaseId;

  @override
  ReleaseBookmarkStatus? build() {
    final value = ref
        .watch(sharedPreferencesProvider)
        .getString('$_prefix$_releaseId');
    return _statusFromName(value);
  }

  Future<void> setStatus(
    ReleaseBookmarkStatus status, {
    DreamRelease? release,
  }) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString('$_prefix$_releaseId', status.name);
    if (release != null) {
      await preferences.setString(
        '$itemPrefix$_releaseId',
        jsonEncode(
          _entryToJson(
            ReleaseBookmarkEntry(
              status: status,
              release: release,
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      );
    }
    state = status;
    ref.invalidate(libraryBookmarksProvider);
  }

  Future<void> remove() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.remove('$_prefix$_releaseId');
    await preferences.remove('$itemPrefix$_releaseId');
    state = null;
    ref.invalidate(libraryBookmarksProvider);
  }
}

ReleaseBookmarkStatus? _statusFromName(String? name) {
  return switch (name) {
    'watching' => ReleaseBookmarkStatus.watching,
    'completed' => ReleaseBookmarkStatus.completed,
    'dropped' => ReleaseBookmarkStatus.dropped,
    'planned' => ReleaseBookmarkStatus.planned,
    _ => null,
  };
}

ReleaseBookmarkEntry? _entryFromJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return null;
  final status = _statusFromName(decoded['status'] as String?);
  final releaseRaw = decoded['release'];
  if (status == null || releaseRaw is! Map) return null;
  return ReleaseBookmarkEntry(
    status: status,
    release: _releaseFromJson(releaseRaw.cast<String, Object?>()),
    updatedAt:
        DateTime.tryParse(decoded['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Map<String, Object?> _entryToJson(ReleaseBookmarkEntry entry) => {
  'status': entry.status.name,
  'updatedAt': entry.updatedAt.toIso8601String(),
  'release': _releaseToJson(entry.release),
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
  );
}

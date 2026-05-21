import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 32)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SettingsRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class PlaybackPositions extends Table {
  TextColumn get releaseId => text()();
  TextColumn get episodeId => text()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {releaseId, episodeId};
}

class StreamSessions extends Table {
  TextColumn get id => text()();
  TextColumn get releaseId => text()();
  TextColumn get episodeId => text()();
  TextColumn get url => text()();
  TextColumn get type => text()();
  IntColumn get quality => integer()();
  TextColumn get headersJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WatchEntries extends Table {
  TextColumn get releaseId => text()();
  TextColumn get episodeId => text()();
  TextColumn get releaseTitle => text()();
  TextColumn get episodeTitle => text()();
  TextColumn get posterUrl => text().nullable()();
  IntColumn get episodeOrdinal => integer()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get isWatched => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {releaseId, episodeId};
}

class DownloadedEpisodes extends Table {
  IntColumn get releaseId => integer()();
  TextColumn get episodeId => text()();
  TextColumn get releaseTitle => text()();
  TextColumn get episodeTitle => text()();
  TextColumn get posterUrl => text().nullable()();
  IntColumn get episodeOrdinal => integer()();
  TextColumn get localFilePath => text()();
  IntColumn get fileSize => integer()();
  IntColumn get downloadedBytes => integer()();
  TextColumn get status =>
      text()(); // 'pending', 'downloading', 'completed', 'failed'
  IntColumn get streamQuality => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {releaseId, episodeId};
}

@DriftDatabase(
  tables: [
    Profiles,
    SettingsRows,
    CacheEntries,
    PlaybackPositions,
    StreamSessions,
    WatchEntries,
    DownloadedEpisodes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(watchEntries);
      }
      if (from < 3) {
        await migrator.createTable(downloadedEpisodes);
      }
    },
  );

  Future<void> saveDownloadedEpisode(DownloadedEpisodesCompanion entry) {
    return into(downloadedEpisodes).insertOnConflictUpdate(entry);
  }

  Future<int> updateDownloadedEpisode(
    int releaseId,
    String episodeId,
    DownloadedEpisodesCompanion changes,
  ) {
    return (update(downloadedEpisodes)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .write(changes);
  }

  Future<DownloadedEpisode?> downloadedEpisode(
    int releaseId,
    String episodeId,
  ) {
    return (select(downloadedEpisodes)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .getSingleOrNull();
  }

  Stream<DownloadedEpisode?> watchDownloadedEpisode(
    int releaseId,
    String episodeId,
  ) {
    return (select(downloadedEpisodes)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .watchSingleOrNull();
  }

  Future<List<DownloadedEpisode>> allDownloadedEpisodes() {
    return select(downloadedEpisodes).get();
  }

  Stream<List<DownloadedEpisode>> watchAllDownloadedEpisodes() {
    return (select(
      downloadedEpisodes,
    )..orderBy([(row) => OrderingTerm.desc(row.createdAt)])).watch();
  }

  Future<int> deleteDownloadedEpisode(int releaseId, String episodeId) {
    return (delete(downloadedEpisodes)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .go();
  }

  Future<int> deleteAllDownloadedEpisodes() {
    return delete(downloadedEpisodes).go();
  }

  Future<Profile?> activeProfile() {
    return (select(
      profiles,
    )..where((row) => row.isActive.equals(true))).getSingleOrNull();
  }

  Future<void> upsertProfile(ProfilesCompanion profile) {
    return into(profiles).insertOnConflictUpdate(profile);
  }

  Future<void> activateProfile(String id) async {
    await transaction(() async {
      await update(
        profiles,
      ).write(const ProfilesCompanion(isActive: Value(false)));
      await (update(profiles)..where((row) => row.id.equals(id))).write(
        const ProfilesCompanion(isActive: Value(true)),
      );
    });
  }

  Future<void> putCacheEntry(CacheEntriesCompanion entry) {
    return into(cacheEntries).insertOnConflictUpdate(entry);
  }

  Future<CacheEntry?> cacheEntry(String key) {
    return (select(
      cacheEntries,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
  }

  Future<int> clearExpiredCache(DateTime now) {
    return (delete(cacheEntries)..where(
          (row) =>
              row.expiresAt.isNotNull() & row.expiresAt.isSmallerThanValue(now),
        ))
        .go();
  }

  Future<List<CacheEntry>> allCacheEntries() {
    return select(cacheEntries).get();
  }

  Future<int> clearAllCache() {
    return delete(cacheEntries).go();
  }

  Future<int> rewriteCacheExpiration(Duration? retention) async {
    final entries = await allCacheEntries();
    await transaction(() async {
      for (final entry in entries) {
        await (update(
          cacheEntries,
        )..where((row) => row.key.equals(entry.key))).write(
          CacheEntriesCompanion(
            expiresAt: Value(
              retention == null ? null : entry.updatedAt.add(retention),
            ),
          ),
        );
      }
    });
    return entries.length;
  }

  Future<void> savePlaybackPosition(PlaybackPositionsCompanion position) {
    return into(playbackPositions).insertOnConflictUpdate(position);
  }

  Future<PlaybackPosition?> playbackPosition(
    String releaseId,
    String episodeId,
  ) {
    return (select(playbackPositions)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .getSingleOrNull();
  }

  Future<void> saveStreamSession(StreamSessionsCompanion session) {
    return into(streamSessions).insertOnConflictUpdate(session);
  }

  Future<StreamSession?> latestStreamSession(
    String releaseId,
    String episodeId,
  ) {
    return (select(streamSessions)
          ..where(
            (row) =>
                row.releaseId.equals(releaseId) &
                row.episodeId.equals(episodeId),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertWatchEntry(WatchEntriesCompanion entry) {
    return into(watchEntries).insertOnConflictUpdate(entry);
  }

  Future<WatchEntry?> watchEntry(String releaseId, String episodeId) {
    return (select(watchEntries)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .getSingleOrNull();
  }

  Stream<WatchEntry?> watchEntryChanges(String releaseId, String episodeId) {
    return (select(watchEntries)..where(
          (row) =>
              row.releaseId.equals(releaseId) & row.episodeId.equals(episodeId),
        ))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Stream<List<WatchEntry>> watchRecentEntries({int limit = 12}) {
    return (select(watchEntries)
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
          ..limit(limit))
        .watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'dream_cast.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

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

@DriftDatabase(
  tables: [
    Profiles,
    SettingsRows,
    CacheEntries,
    PlaybackPositions,
    StreamSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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

  Future<void> savePlaybackPosition(PlaybackPositionsCompanion position) {
    return into(playbackPositions).insertOnConflictUpdate(position);
  }

  Future<void> saveStreamSession(StreamSessionsCompanion session) {
    return into(streamSessions).insertOnConflictUpdate(session);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'dream_cast.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/profile/domain/local_profile.dart';
import 'package:drift/drift.dart';

final class ProfileRepository {
  const ProfileRepository(this._database);

  final AppDatabase _database;

  Future<LocalProfile?> activeProfile() async {
    final row = await _database.activeProfile();
    return row == null ? null : _map(row);
  }

  Future<LocalProfile> createOrUpdateActiveProfile(String name) async {
    final current = await _database.activeProfile();
    final now = DateTime.now();
    final id = current?.id ?? 'profile_${now.microsecondsSinceEpoch}';

    await _database.upsertProfile(
      ProfilesCompanion(
        id: Value(id),
        name: Value(name.trim()),
        createdAt: Value(current?.createdAt ?? now),
        updatedAt: Value(now),
        isActive: const Value(true),
      ),
    );
    await _database.activateProfile(id);

    return LocalProfile(
      id: id,
      name: name.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
  }

  LocalProfile _map(Profile row) {
    return LocalProfile(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/core/errors/app_exception.dart';
import 'package:dream_cast/features/profile/data/profile_repository.dart';
import 'package:dream_cast/features/profile/domain/local_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

final activeProfileProvider =
    AsyncNotifierProvider<ActiveProfileController, LocalProfile?>(
      ActiveProfileController.new,
    );

final class ActiveProfileController extends AsyncNotifier<LocalProfile?> {
  @override
  Future<LocalProfile?> build() {
    return ref.watch(profileRepositoryProvider).activeProfile();
  }

  Future<void> save(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 2) {
      throw const ProfileException(
        'Введите имя длиной не меньше двух символов.',
      );
    }

    state = const AsyncLoading<LocalProfile?>();
    final saved = await ref
        .read(profileRepositoryProvider)
        .createOrUpdateActiveProfile(trimmed);
    state = AsyncData<LocalProfile?>(saved);
  }
}

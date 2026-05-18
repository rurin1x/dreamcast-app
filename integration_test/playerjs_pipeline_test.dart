import 'package:dream_cast/app/bootstrap/app_bootstrap.dart';
import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/features/releases/data/release_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dream Cast PlayerJS pipeline works on device build', (
    tester,
  ) async {
    final bootstrap = await AppBootstrap.start();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(bootstrap.preferences),
        appDatabaseProvider.overrideWithValue(bootstrap.database),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(bootstrap.database.close);

    final repository = container.read(releaseRepositoryProvider);
    final releases = await repository.ongoing(page: 1, pageSize: 8);

    Object? lastError;
    StackTrace? lastStackTrace;

    for (final release in releases.items) {
      try {
        final detail = await repository.getDetail(release);
        final episodes = await repository.getEpisodes(detail.value);

        expect(
          episodes.value,
          isNotEmpty,
          reason: 'Release ${release.id} (${release.title}) has no episodes',
        );
        expect(
          episodes.value.first.file,
          isNotEmpty,
          reason: 'First episode file is empty for ${release.id}',
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }

    fail(
      'No release from the first page produced episodes. '
      'lastError=$lastError\nlastStackTrace=$lastStackTrace',
    );
  });
}

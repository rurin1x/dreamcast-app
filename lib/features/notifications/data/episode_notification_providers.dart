import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_service.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_storage.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_subscription.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_worker.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final episodeNotificationSubscriptionProvider =
    NotifierProvider.family<
      EpisodeNotificationSubscriptionController,
      bool,
      int
    >(EpisodeNotificationSubscriptionController.new);

final episodeNotificationSubscriptionsProvider =
    NotifierProvider<
      EpisodeNotificationSubscriptionsController,
      List<EpisodeNotificationSubscription>
    >(EpisodeNotificationSubscriptionsController.new);

final class EpisodeNotificationSubscriptionsController
    extends Notifier<List<EpisodeNotificationSubscription>> {
  @override
  List<EpisodeNotificationSubscription> build() {
    return EpisodeNotificationStorage.readAll(
      ref.watch(sharedPreferencesProvider),
    );
  }
}

final class EpisodeNotificationSubscriptionController extends Notifier<bool> {
  EpisodeNotificationSubscriptionController(this._releaseId);

  final int _releaseId;

  @override
  bool build() {
    return EpisodeNotificationStorage.isSubscribed(
      ref.watch(sharedPreferencesProvider),
      _releaseId,
    );
  }

  Future<bool> enable(DreamRelease release) async {
    final granted = await EpisodeNotificationService.requestPermission();
    if (!granted) return false;

    final preferences = ref.read(sharedPreferencesProvider);
    final existing = EpisodeNotificationStorage.read(preferences, release.id);
    await EpisodeNotificationStorage.save(
      preferences,
      EpisodeNotificationSubscription(
        release: release,
        lastKnownEpisodes:
            existing?.lastKnownEpisodes ?? knownEpisodeCount(release),
        updatedAt: DateTime.now(),
      ),
    );
    state = true;
    ref.invalidate(episodeNotificationSubscriptionsProvider);
    await EpisodeNotificationScheduler.syncFromPreferences(preferences);
    await EpisodeNotificationScheduler.scheduleOneOff(
      initialDelay: const Duration(minutes: 1),
    );
    return true;
  }

  Future<void> disable() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await EpisodeNotificationStorage.remove(preferences, _releaseId);
    state = false;
    ref.invalidate(episodeNotificationSubscriptionsProvider);
    await EpisodeNotificationScheduler.syncFromPreferences(preferences);
  }
}

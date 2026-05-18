import 'dart:async';

import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history_storage.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationTapProvider = StreamProvider<String>(
  (ref) => EpisodeNotificationService.tapStream,
);

final episodeNotificationHistoryProvider =
    NotifierProvider<
      EpisodeNotificationHistoryController,
      List<EpisodeNotificationHistoryEntry>
    >(EpisodeNotificationHistoryController.new);

final unreadEpisodeNotificationsProvider = Provider<int>((ref) {
  return ref
      .watch(episodeNotificationHistoryProvider)
      .where((entry) => !entry.isRead)
      .length;
});

final class EpisodeNotificationHistoryController
    extends Notifier<List<EpisodeNotificationHistoryEntry>> {
  @override
  List<EpisodeNotificationHistoryEntry> build() {
    return EpisodeNotificationHistoryStorage.readAll(
      ref.watch(sharedPreferencesProvider),
    );
  }

  Future<void> refresh() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.reload();
    state = EpisodeNotificationHistoryStorage.readAll(preferences);
  }

  Future<void> markRead(String id) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.reload();
    await EpisodeNotificationHistoryStorage.markRead(preferences, id);
    state = EpisodeNotificationHistoryStorage.readAll(preferences);
  }

  Future<void> markAllRead() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.reload();
    await EpisodeNotificationHistoryStorage.markAllRead(preferences);
    state = EpisodeNotificationHistoryStorage.readAll(preferences);
  }

  Future<void> clearAll() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.reload();
    await EpisodeNotificationHistoryStorage.clearAll(preferences);
    state = const [];
  }

  Future<EpisodeNotificationHistoryEntry?> consumePendingTap() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.reload();
    final id = await EpisodeNotificationHistoryStorage.consumePendingTap(
      preferences,
    );
    if (id == null) return null;
    await EpisodeNotificationHistoryStorage.markRead(preferences, id);
    state = EpisodeNotificationHistoryStorage.readAll(preferences);
    return EpisodeNotificationHistoryStorage.read(preferences, id);
  }
}

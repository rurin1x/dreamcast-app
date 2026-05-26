import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dream_cast/core/network/network_config.dart';
import 'package:dream_cast/features/downloads/data/download_service.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history_storage.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_service.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_storage.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_subscription.dart';
import 'package:dream_cast/features/releases/data/dream_cast_api.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const episodeNotificationTaskName = 'dream_cast_episode_notification_check';
const episodeNotificationUniqueName =
    'dream_cast_episode_notification_periodic';
const episodeNotificationOneOffUniqueName =
    'dream_cast_episode_notification_once';

@pragma('vm:entry-point')
void episodeNotificationCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName == downloadEpisodeTaskName) {
      return DownloadService.runBackgroundTask(inputData);
    }

    if (taskName == downloadEpisodeBatchTaskName) {
      return DownloadService.runBackgroundBatchTask(inputData);
    }

    if (taskName != episodeNotificationTaskName) return true;

    try {
      await EpisodeNotificationWorker.run();
      return true;
    } catch (_) {
      return false;
    }
  });
}

final class EpisodeNotificationWorker {
  const EpisodeNotificationWorker._();

  static Future<void> run() async {
    final preferences = await SharedPreferences.getInstance();
    final subscriptions = EpisodeNotificationStorage.readAll(preferences);
    if (subscriptions.isEmpty) return;

    final api = DreamCastApi(_createDio());
    final freshById = <int, DreamRelease>{};

    try {
      final latest = await api.getReleases(page: 1, pageSize: 64);
      for (final dto in latest.releases) {
        final release = dto.toDomain();
        freshById[release.id] = release;
      }
    } catch (_) {
      // Individual searches below still give subscribed titles a chance to
      // update if the general latest request is unavailable.
    }

    for (final subscription in subscriptions.take(40)) {
      final freshRelease =
          freshById[subscription.release.id] ??
          await _findRelease(api, subscription.release);
      if (freshRelease == null) continue;

      final currentCount = knownEpisodeCount(freshRelease);
      final previousCount = subscription.lastKnownEpisodes;

      if (currentCount > previousCount && previousCount > 0) {
        final entry = EpisodeNotificationHistoryEntry.create(
          release: freshRelease,
          previousCount: previousCount,
          currentCount: currentCount,
        );
        await EpisodeNotificationHistoryStorage.save(preferences, entry);
        await EpisodeNotificationService.showNewEpisodes(entry: entry);
      }

      if (currentCount != previousCount) {
        await EpisodeNotificationStorage.save(
          preferences,
          subscription.copyWith(
            release: freshRelease,
            lastKnownEpisodes: currentCount,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  static Future<DreamRelease?> _findRelease(
    DreamCastApi api,
    DreamRelease release,
  ) async {
    try {
      final result = await api.getReleases(
        query: release.title,
        page: 1,
        pageSize: 10,
      );
      for (final dto in result.releases) {
        final candidate = dto.toDomain();
        if (candidate.id == release.id) return candidate;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Dio _createDio() {
    const config = NetworkConfig();
    return Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: config.browserLikeHeaders,
      ),
    );
  }
}

final class EpisodeNotificationScheduler {
  const EpisodeNotificationScheduler._();

  static Future<void>? _initializeFuture;

  static Future<void> initialize() {
    return _initializeFuture ??= Workmanager().initialize(
      episodeNotificationCallbackDispatcher,
    );
  }

  static Future<void> syncFromPreferences(SharedPreferences preferences) async {
    await initialize();
    final subscriptions = EpisodeNotificationStorage.readAll(preferences);
    if (subscriptions.isEmpty) {
      await Workmanager().cancelByUniqueName(episodeNotificationUniqueName);
      await Workmanager().cancelByUniqueName(
        episodeNotificationOneOffUniqueName,
      );
      return;
    }
    await schedule();
    await scheduleOneOff();
  }

  static Future<void> schedule() async {
    await initialize();
    return Workmanager().registerPeriodicTask(
      episodeNotificationUniqueName,
      episodeNotificationTaskName,
      frequency: const Duration(minutes: 30),
      flexInterval: const Duration(minutes: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  static Future<void> scheduleOneOff({
    Duration initialDelay = const Duration(minutes: 15),
  }) async {
    await initialize();
    return Workmanager().registerOneOffTask(
      episodeNotificationOneOffUniqueName,
      episodeNotificationTaskName,
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
}

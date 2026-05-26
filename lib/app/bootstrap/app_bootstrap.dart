import 'dart:async';

import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_service.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_worker.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AppBootstrapResult {
  const AppBootstrapResult({required this.preferences, required this.database});

  final SharedPreferences preferences;
  final AppDatabase database;
}

final class AppBootstrap {
  const AppBootstrap._();

  static Future<AppBootstrapResult> start() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureAppLogging();

    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase();
    try {
      await EpisodeNotificationScheduler.initialize();
    } catch (error, stackTrace) {
      appLogger(
        'bootstrap',
      ).warning('WorkManager startup failed: $error', stackTrace);
    }
    unawaited(_startBackgroundServices(preferences));

    return AppBootstrapResult(preferences: preferences, database: database);
  }

  static Future<void> _startBackgroundServices(
    SharedPreferences preferences,
  ) async {
    try {
      await EpisodeNotificationService.initialize().timeout(
        const Duration(seconds: 3),
      );
      await EpisodeNotificationScheduler.syncFromPreferences(
        preferences,
      ).timeout(const Duration(seconds: 3));
    } catch (error, stackTrace) {
      appLogger(
        'bootstrap',
      ).warning('Background services startup failed: $error', stackTrace);
    }
  }
}

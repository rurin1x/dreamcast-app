import 'dart:async';

import 'package:dream_cast/features/notifications/data/episode_notification_history.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class EpisodeNotificationService {
  const EpisodeNotificationService._();

  static const channelId = 'dream_cast_new_episodes';
  static const channelName = 'Новые серии';
  static const channelDescription =
      'Уведомления о новых сериях в подписанных тайтлах.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final _tapController = StreamController<String>.broadcast();
  static bool _initialized = false;

  static Stream<String> get tapStream => _tapController.stream;

  static Future<void> initialize() async {
    if (_initialized) return;
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
    await _rememberLaunchNotification();
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> showNewEpisodes({
    required EpisodeNotificationHistoryEntry entry,
  }) async {
    await initialize();

    await _plugin.show(
      id: entry.release.id,
      title: entry.release.title,
      body: entry.message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: entry.id,
    );
  }

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final id = response.payload;
    if (id == null || id.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await EpisodeNotificationHistoryStorage.setPendingTap(preferences, id);
    _tapController.add(id);
  }

  static Future<void> _rememberLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    final id = response?.payload;
    if (details?.didNotificationLaunchApp == true &&
        id != null &&
        id.isNotEmpty) {
      final preferences = await SharedPreferences.getInstance();
      await EpisodeNotificationHistoryStorage.setPendingTap(preferences, id);
    }
  }
}

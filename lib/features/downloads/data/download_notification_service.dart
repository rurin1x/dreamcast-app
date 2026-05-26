import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final class DownloadNotificationService {
  const DownloadNotificationService._();

  static const channelId = 'dream_cast_downloads';
  static const channelName = 'Загрузки серий';
  static const channelDescription = 'Прогресс офлайн-загрузки серий.';
  static const smallIcon = '@drawable/ic_stat_dream_cast';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await _ignoreNotificationErrors(() async {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings(smallIcon),
      );
      await _plugin.initialize(settings: initializationSettings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low,
          showBadge: false,
        ),
      );
      _initialized = true;
    });
  }

  static Future<void> requestPermission() async {
    await initialize();
    await _ignoreNotificationErrors(() async {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    });
  }

  static Future<void> showQueued({
    required DreamRelease release,
    required DreamEpisode episode,
  }) async {
    await requestPermission();
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: _notificationId(release.id, episode.id),
        title: 'Подготовка загрузки',
        body: '${release.title} • ${episode.title}',
        notificationDetails: _details(indeterminate: true),
      );
    });
  }

  static Future<void> showProgress({
    required DreamRelease release,
    required DreamEpisode episode,
    required int downloaded,
    required int total,
  }) async {
    await initialize();
    final safeTotal = total <= 0 ? 1 : total;
    final safeDownloaded = downloaded.clamp(0, safeTotal);
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: _notificationId(release.id, episode.id),
        title: 'Загрузка серии',
        body: '${release.title} • ${episode.title}',
        notificationDetails: _details(
          progress: safeDownloaded,
          maxProgress: safeTotal,
        ),
      );
    });
  }

  static Future<void> showCompleted({
    required DreamRelease release,
    required DreamEpisode episode,
  }) async {
    await initialize();
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: _notificationId(release.id, episode.id),
        title: 'Серия скачана',
        body: '${release.title} • ${episode.title}',
        notificationDetails: _finalDetails(),
      );
    });
  }

  static Future<void> showFailed({
    required DreamRelease release,
    required DreamEpisode episode,
  }) async {
    await initialize();
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: _notificationId(release.id, episode.id),
        title: 'Загрузка не удалась',
        body: '${release.title} • ${episode.title}',
        notificationDetails: _finalDetails(
          importance: Importance.defaultImportance,
        ),
      );
    });
  }

  static Future<void> showBatchProgress({
    required String batchId,
    required String title,
    required int completed,
    required int failed,
    required int total,
  }) async {
    await initialize();
    final safeTotal = total <= 0 ? 1 : total;
    final done = (completed + failed).clamp(0, safeTotal);
    final finished = done >= safeTotal;
    final notificationTitle = finished
        ? (failed > 0 ? 'Загрузка завершена с ошибками' : 'Серии скачаны')
        : 'Загрузка серий';
    final body = failed > 0
        ? '$title • готово $completed из $total, ошибок: $failed'
        : '$title • готово $completed из $total';

    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: _batchNotificationId(batchId),
        title: notificationTitle,
        body: body,
        notificationDetails: _details(
          progress: done,
          maxProgress: safeTotal,
          ongoing: !finished,
        ),
      );
    });
  }

  static Future<void> cancel({
    required int releaseId,
    required String episodeId,
  }) async {
    await initialize();
    await _ignoreNotificationErrors(() {
      return _plugin.cancel(id: _notificationId(releaseId, episodeId));
    });
  }

  static NotificationDetails _details({
    int progress = 0,
    int maxProgress = 0,
    bool indeterminate = false,
    bool ongoing = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        category: AndroidNotificationCategory.progress,
        icon: smallIcon,
        ongoing: ongoing,
        autoCancel: !ongoing,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: indeterminate,
        progress: progress,
        maxProgress: maxProgress,
      ),
    );
  }

  static NotificationDetails _finalDetails({
    Importance importance = Importance.low,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: importance == Importance.low
            ? Priority.low
            : Priority.defaultPriority,
        category: AndroidNotificationCategory.progress,
        icon: smallIcon,
        onlyAlertOnce: true,
      ),
    );
  }

  static int _notificationId(int releaseId, String episodeId) {
    var hash = 0x1fffffff & releaseId;
    for (final codeUnit in episodeId.codeUnits) {
      hash = 0x1fffffff & ((hash * 31) + codeUnit);
    }
    return hash == 0 ? releaseId : hash;
  }

  static int _batchNotificationId(String batchId) {
    var hash = 0x13579bdf;
    for (final codeUnit in batchId.codeUnits) {
      hash = 0x1fffffff & ((hash * 33) ^ codeUnit);
    }
    return hash == 0 ? 1 : hash;
  }

  static Future<void> _ignoreNotificationErrors(
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      // Notifications are helpful, but they must never break the download.
    }
  }
}

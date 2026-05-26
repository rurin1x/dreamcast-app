import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final class DownloadNotificationService {
  const DownloadNotificationService._();

  static final _logger = appLogger('downloads.notifications');

  static const channelId = 'dream_cast_downloads_v2';
  static const channelName = 'Загрузки серий';
  static const channelDescription = 'Прогресс офлайн-загрузки серий.';
  static const smallIcon = 'ic_stat_dream_cast';
  static const activeForegroundNotificationId = 3101;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
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
          importance: Importance.defaultImportance,
          showBadge: false,
        ),
      );
      _initialized = true;
    } catch (error, stackTrace) {
      _logger.warning(
        'Не удалось инициализировать уведомления загрузок: $error',
        stackTrace,
      );
    }
  }

  static Future<bool> requestPermission() async {
    await initialize();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (error, stackTrace) {
      _logger.warning(
        'Не удалось запросить разрешение уведомлений загрузок: $error',
        stackTrace,
      );
      return false;
    }
  }

  static Future<void> showQueued({
    required DreamRelease release,
    required DreamEpisode episode,
    int? notificationId,
  }) async {
    final allowed = await requestPermission();
    _logger.info(
      'Показываем уведомление очереди загрузки: allowed=$allowed, '
      'release=${release.id}, episode=${episode.id}',
    );
    await _showProgressNotification(
      id: notificationId ?? _notificationId(release.id, episode.id),
      title: 'Подготовка загрузки',
      body: '${release.title} • ${episode.title}',
      details: _androidDetails(indeterminate: true),
    );
  }

  static Future<void> showProgress({
    required DreamRelease release,
    required DreamEpisode episode,
    required int downloaded,
    required int total,
    int? notificationId,
  }) async {
    final allowed = await requestPermission();
    final safeTotal = total <= 0 ? 1 : total;
    final safeDownloaded = downloaded.clamp(0, safeTotal);
    _logger.info(
      'Обновляем уведомление загрузки: allowed=$allowed, '
      'release=${release.id}, episode=${episode.id}, '
      'progress=$safeDownloaded/$safeTotal',
    );
    await _showProgressNotification(
      id: notificationId ?? _notificationId(release.id, episode.id),
      title: 'Загрузка серии',
      body: '${release.title} • ${episode.title}',
      details: _androidDetails(
        progress: safeDownloaded,
        maxProgress: safeTotal,
      ),
    );
  }

  static Future<void> showCompleted({
    required DreamRelease release,
    required DreamEpisode episode,
    int? notificationId,
  }) async {
    await requestPermission();
    await stopForeground();
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: notificationId ?? _notificationId(release.id, episode.id),
        title: 'Серия скачана',
        body: '${release.title} • ${episode.title}',
        notificationDetails: _finalDetails(),
      );
    });
  }

  static Future<void> showFailed({
    required DreamRelease release,
    required DreamEpisode episode,
    int? notificationId,
  }) async {
    await requestPermission();
    await stopForeground();
    await _ignoreNotificationErrors(() {
      return _plugin.show(
        id: notificationId ?? _notificationId(release.id, episode.id),
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
    int? notificationId,
  }) async {
    final allowed = await requestPermission();
    final safeTotal = total <= 0 ? 1 : total;
    final done = (completed + failed).clamp(0, safeTotal);
    final finished = done >= safeTotal;
    final notificationTitle = finished
        ? (failed > 0 ? 'Загрузка завершена с ошибками' : 'Серии скачаны')
        : 'Загрузка серий';
    final body = failed > 0
        ? '$title • готово $completed из $total, ошибок: $failed'
        : '$title • готово $completed из $total';
    _logger.info(
      'Обновляем batch-уведомление загрузки: allowed=$allowed, '
      'batch=$batchId, progress=$done/$safeTotal',
    );

    if (finished) {
      await stopForeground();
      await _ignoreNotificationErrors(() {
        return _plugin.show(
          id: notificationId ?? _batchNotificationId(batchId),
          title: notificationTitle,
          body: body,
          notificationDetails: _finalDetails(),
        );
      });
      return;
    }

    await _showProgressNotification(
      id: notificationId ?? _batchNotificationId(batchId),
      title: notificationTitle,
      body: body,
      details: _androidDetails(progress: done, maxProgress: safeTotal),
    );
  }

  static Future<void> cancel({
    required int releaseId,
    required String episodeId,
  }) async {
    await initialize();
    await stopForeground();
    await _ignoreNotificationErrors(() {
      return _plugin.cancel(id: _notificationId(releaseId, episodeId));
    });
  }

  static Future<void> stopForeground() async {
    await _ignoreNotificationErrors(() async {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.stopForegroundService();
    });
  }

  static Future<void> _showProgressNotification({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationDetails details,
  }) async {
    await _ignoreNotificationErrors(() async {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
      );
    });
  }

  static AndroidNotificationDetails _androidDetails({
    int progress = 0,
    int maxProgress = 0,
    bool indeterminate = false,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.progress,
      icon: smallIcon,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: true,
      indeterminate: indeterminate,
      progress: progress,
      maxProgress: maxProgress,
    );
  }

  static NotificationDetails _finalDetails({
    Importance importance = Importance.defaultImportance,
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
    } catch (error, stackTrace) {
      _logger.warning('Ошибка показа уведомления загрузки: $error', stackTrace);
    }
  }
}

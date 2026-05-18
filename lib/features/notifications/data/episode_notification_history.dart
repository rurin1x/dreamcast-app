import 'package:dream_cast/features/releases/domain/release.dart';

final class EpisodeNotificationHistoryEntry {
  const EpisodeNotificationHistoryEntry({
    required this.id,
    required this.release,
    required this.message,
    required this.previousCount,
    required this.currentCount,
    required this.createdAt,
    this.readAt,
  });

  factory EpisodeNotificationHistoryEntry.create({
    required DreamRelease release,
    required int previousCount,
    required int currentCount,
  }) {
    final now = DateTime.now();
    return EpisodeNotificationHistoryEntry(
      id: '${release.id}_${currentCount}_${now.microsecondsSinceEpoch}',
      release: release,
      message: episodeNotificationMessage(
        previousCount: previousCount,
        currentCount: currentCount,
      ),
      previousCount: previousCount,
      currentCount: currentCount,
      createdAt: now,
    );
  }

  final String id;
  final DreamRelease release;
  final String message;
  final int previousCount;
  final int currentCount;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  EpisodeNotificationHistoryEntry copyWith({
    DreamRelease? release,
    String? message,
    int? previousCount,
    int? currentCount,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return EpisodeNotificationHistoryEntry(
      id: id,
      release: release ?? this.release,
      message: message ?? this.message,
      previousCount: previousCount ?? this.previousCount,
      currentCount: currentCount ?? this.currentCount,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

String episodeNotificationMessage({
  required int previousCount,
  required int currentCount,
}) {
  final firstNew = previousCount + 1;
  if (currentCount <= firstNew) return 'Вышла $currentCount серия.';
  return 'Вышли серии $firstNew-$currentCount.';
}

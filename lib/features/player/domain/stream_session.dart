import 'package:dream_cast/features/player/domain/video_stream.dart';

final class StreamSession {
  const StreamSession({
    required this.id,
    required this.releaseId,
    required this.episodeId,
    required this.stream,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String releaseId;
  final String episodeId;
  final VideoStream stream;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

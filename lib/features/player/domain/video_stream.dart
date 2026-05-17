enum VideoStreamType { hls, dash, mp4, webm, audio }

final class VideoStream {
  const VideoStream({
    required this.url,
    required this.type,
    required this.quality,
    this.headers = const {},
  });

  final Uri url;
  final VideoStreamType type;
  final int quality;
  final Map<String, String> headers;
}

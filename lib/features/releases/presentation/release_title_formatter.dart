import 'package:dream_cast/features/releases/domain/release.dart';

String displayReleaseTitle(DreamRelease release) {
  return cleanReleaseTitle(release.title);
}

String displayDetailTitle(DreamReleaseDetail detail) {
  return cleanReleaseTitle(detail.title);
}

String cleanReleaseTitle(String value) {
  final trimmed = value.trim();
  final slashIndex = trimmed.indexOf(' / ');
  if (slashIndex <= 0) return trimmed;
  return trimmed.substring(0, slashIndex).trim();
}

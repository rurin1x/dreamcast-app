String? normalizeDreamCastUrl(
  String? raw, {
  String baseUrl = 'https://dreamerscast.com',
}) {
  if (raw == null || raw.trim().isEmpty) return null;
  var value = raw.trim();
  if (value.startsWith('//')) {
    value = 'https:$value';
  }
  try {
    return Uri.parse(baseUrl).resolve(value).toString();
  } catch (_) {
    return value;
  }
}

String? normalizeDreamCastImageUrl(
  String? raw, {
  String baseCacheUrl = 'https://cache.dreamerscast.com',
}) {
  return normalizeDreamCastUrl(raw, baseUrl: baseCacheUrl);
}

bool isValidHttpUrl(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

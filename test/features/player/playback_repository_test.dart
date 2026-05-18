import 'package:dream_cast/features/player/data/playback_repository.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uniqueRecentContinueWatchingItems', () {
    test('keeps the latest episode per release and limits to five titles', () {
      final base = DateTime(2026, 5, 18, 12);
      final items = [
        _item(
          releaseId: '1',
          episodeId: 'anime-1-episode-4',
          episodeOrdinal: 4,
          updatedAt: base.add(const Duration(minutes: 1)),
        ),
        _item(
          releaseId: '2',
          episodeId: 'anime-2-episode-2',
          episodeOrdinal: 2,
          updatedAt: base.add(const Duration(minutes: 2)),
        ),
        _item(
          releaseId: '1',
          episodeId: 'anime-1-episode-2',
          episodeOrdinal: 2,
          updatedAt: base.add(const Duration(minutes: 3)),
        ),
        _item(
          releaseId: '3',
          episodeId: 'anime-3-episode-1',
          updatedAt: base.add(const Duration(minutes: 4)),
        ),
        _item(
          releaseId: '4',
          episodeId: 'anime-4-episode-1',
          updatedAt: base.add(const Duration(minutes: 5)),
        ),
        _item(
          releaseId: '5',
          episodeId: 'anime-5-episode-1',
          updatedAt: base.add(const Duration(minutes: 6)),
        ),
        _item(
          releaseId: '6',
          episodeId: 'anime-6-episode-1',
          updatedAt: base.add(const Duration(minutes: 7)),
        ),
      ];

      final result = uniqueRecentContinueWatchingItems(items);

      expect(result, hasLength(5));
      expect(result.map((item) => item.releaseId), ['6', '5', '4', '3', '1']);
      expect(result.last.episodeId, 'anime-1-episode-2');
      expect(
        result.any((item) => item.episodeId == 'anime-1-episode-4'),
        isFalse,
      );
    });
  });
}

ContinueWatchingItem _item({
  required String releaseId,
  required String episodeId,
  int episodeOrdinal = 1,
  required DateTime updatedAt,
}) {
  return ContinueWatchingItem(
    releaseId: releaseId,
    episodeId: episodeId,
    releaseTitle: 'Аниме $releaseId',
    episodeTitle: 'Серия $episodeOrdinal',
    episodeOrdinal: episodeOrdinal,
    position: const Duration(minutes: 5),
    duration: const Duration(minutes: 24),
    updatedAt: updatedAt,
    isWatched: false,
  );
}

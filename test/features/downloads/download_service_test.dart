import 'package:dio/dio.dart';
import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/features/downloads/data/download_service.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Dio dio;
  late DownloadService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = Dio();
    service = DownloadService(db, dio);
  });

  tearDown(() async {
    await db.close();
  });

  group('DownloadService HLS parser & helper unit tests', () {
    test('Initializes database record as pending', () async {
      final release = DreamRelease(
        id: 123,
        title: 'Test Release',
        originalTitle: 'Test Original Title',
        url: 'https://example.com/release',
        posterUrl: 'https://example.com/poster.jpg',
      );

      final episode = DreamEpisode(
        id: 'ep_1',
        releaseId: 123,
        ordinal: 1,
        title: 'Episode 1',
        file: 'ep1.ts',
      );

      final stream = DreamStream(
        id: 'stream_1',
        releaseId: 123,
        episodeId: 'ep_1',
        url: Uri.parse('https://example.com/stream/master.m3u8'),
        type: DreamStreamType.hls,
        quality: 1080,
      );

      // Start download
      await service.startDownload(
        release: release,
        episode: episode,
        stream: stream,
      );

      // Verify the record is in pending state in DB
      final record = await db.downloadedEpisode(123, 'ep_1');
      expect(record, isNotNull);
      expect(record!.releaseTitle, equals('Test Release'));
      expect(record.episodeTitle, equals('Episode 1'));
      expect(record.status, equals('pending'));
      expect(record.streamQuality, equals(1080));
    });
  });
}

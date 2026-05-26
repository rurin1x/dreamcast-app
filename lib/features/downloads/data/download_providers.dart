import 'dart:async';

import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/core/network/dio_provider.dart';
import 'package:dream_cast/features/downloads/data/download_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final downloadedEpisodesStreamProvider =
    StreamProvider<List<DownloadedEpisode>>((ref) {
      return _pollDownloads(ref.watch(appDatabaseProvider));
    });

final downloadedEpisodeStreamProvider =
    StreamProvider.family<
      DownloadedEpisode?,
      ({int releaseId, String episodeId})
    >((ref, arg) {
      return _pollDownload(
        ref.watch(appDatabaseProvider),
        releaseId: arg.releaseId,
        episodeId: arg.episodeId,
      );
    });

Stream<List<DownloadedEpisode>> _pollDownloads(AppDatabase database) async* {
  yield await database.allDownloadedEpisodes();
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 1))) {
    yield await database.allDownloadedEpisodes();
  }
}

Stream<DownloadedEpisode?> _pollDownload(
  AppDatabase database, {
  required int releaseId,
  required String episodeId,
}) async* {
  yield await database.downloadedEpisode(releaseId, episodeId);
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 1))) {
    yield await database.downloadedEpisode(releaseId, episodeId);
  }
}

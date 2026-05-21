import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/core/network/dio_provider.dart';
import 'package:dream_cast/features/downloads/data/download_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_cast/core/database/app_database.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final downloadedEpisodesStreamProvider = StreamProvider<List<DownloadedEpisode>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllDownloadedEpisodes();
});

final downloadedEpisodeStreamProvider = StreamProvider.family<DownloadedEpisode?, ({int releaseId, String episodeId})>((ref, arg) {
  return ref.watch(appDatabaseProvider).watchDownloadedEpisode(arg.releaseId, arg.episodeId);
});

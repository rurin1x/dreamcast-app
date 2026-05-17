import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/features/player/data/playback_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playbackRepositoryProvider = Provider<PlaybackRepository>(
  (ref) => PlaybackRepository(ref.watch(appDatabaseProvider)),
);

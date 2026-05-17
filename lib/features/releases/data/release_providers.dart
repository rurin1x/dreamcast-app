import 'package:dream_cast/core/cache/cache_providers.dart';
import 'package:dream_cast/features/releases/data/dream_cast_api.dart';
import 'package:dream_cast/features/releases/data/dream_cast_parser_service.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dreamCastParserServiceProvider = Provider<DreamCastParserService>(
  (ref) => const DreamCastParserService(),
);

final releaseRepositoryProvider = Provider<ReleaseRepository>(
  (ref) => ReleaseRepository(
    api: ref.watch(dreamCastApiProvider),
    cache: ref.watch(cacheRepositoryProvider),
    parser: ref.watch(dreamCastParserServiceProvider),
  ),
);

import 'package:dio/dio.dart';
import 'package:dream_cast/features/releases/data/release_providers.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:dream_cast/features/schedule/domain/release_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final releaseScheduleProvider = FutureProvider<DreamData<ReleaseSchedule>>((
  ref,
) {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .watch(releaseRepositoryProvider)
      .getSchedule(cancelToken: cancelToken);
});

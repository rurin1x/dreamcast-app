import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:dream_cast/features/releases/domain/release.dart';

const dreamCastDiagnosticsEnabled = bool.fromEnvironment(
  'DREAM_CAST_DIAGNOSTICS',
  defaultValue: false,
);

const playerJsDiagnosticsEnabled = bool.fromEnvironment(
  'PLAYERJS_DIAGNOSTICS',
  defaultValue: false,
);

final _log = appLogger('dreamcast');

void logDreamCastDiagnostic(String message) {
  if (!dreamCastDiagnosticsEnabled) return;
  _log.info(message);
}

void logPlayerJsDiagnostic(String message) {
  if (!dreamCastDiagnosticsEnabled && !playerJsDiagnosticsEnabled) return;
  _log.info('[PlayerJS] $message');
}

void logReleaseSample({
  required String source,
  required List<DreamRelease> releases,
  required int totalCount,
  required bool isStale,
}) {
  if (!dreamCastDiagnosticsEnabled) return;

  final first = releases.isEmpty ? null : releases.first;
  _log.info(
    '$source: releases=${releases.length}, total=$totalCount, stale=$isStale, '
    'first="${first?.title}", poster="${first?.posterUrl}", '
    'posterValid=${isValidHttpUrl(first?.posterUrl)}',
  );
}

import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _log = appLogger('riverpod');

final class RiverpodLogger extends ProviderObserver {
  const RiverpodLogger();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _log.warning(
      'Provider failed: ${context.provider.name ?? context.provider}',
      error,
      stackTrace,
    );
  }
}

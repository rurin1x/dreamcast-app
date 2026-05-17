import 'package:logging/logging.dart';

Logger appLogger(String name) => Logger('dream_cast.$name');

void configureAppLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Keep logging centralized so release builds can later redirect this
    // stream to crash reporting without changing feature code.
    // ignore: avoid_print
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });
}

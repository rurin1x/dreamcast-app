import 'package:dream_cast/core/database/app_database.dart';
import 'package:dream_cast/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AppBootstrapResult {
  const AppBootstrapResult({required this.preferences, required this.database});

  final SharedPreferences preferences;
  final AppDatabase database;
}

final class AppBootstrap {
  const AppBootstrap._();

  static Future<AppBootstrapResult> start() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureAppLogging();

    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase();

    return AppBootstrapResult(preferences: preferences, database: database);
  }
}

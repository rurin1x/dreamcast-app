import 'package:dream_cast/app/bootstrap/app_bootstrap.dart';
import 'package:dream_cast/app/router/app_router.dart';
import 'package:dream_cast/app/theme/app_theme.dart';
import 'package:dream_cast/core/database/database_providers.dart';
import 'package:dream_cast/core/logging/riverpod_logger.dart';
import 'package:dream_cast/core/settings/settings_providers.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden.'),
);

class DreamCastApp extends StatelessWidget {
  const DreamCastApp({required this.bootstrap, super.key});

  final AppBootstrapResult bootstrap;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: const [RiverpodLogger()],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(bootstrap.preferences),
        appDatabaseProvider.overrideWithValue(bootstrap.database),
      ],
      child: const _DreamCastMaterialApp(),
    );
  }
}

class _DreamCastMaterialApp extends ConsumerWidget {
  const _DreamCastMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final themeBundle = AppTheme.build(
          settings: settings,
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Dream Cast',
          routerConfig: router,
          themeMode: settings.themeMode,
          theme: themeBundle.light,
          darkTheme: themeBundle.dark,
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: const _AndroidScrollBehavior(),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

class _AndroidScrollBehavior extends MaterialScrollBehavior {
  const _AndroidScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) => TargetPlatform.android;
}

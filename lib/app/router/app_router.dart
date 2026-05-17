import 'package:animations/animations.dart';
import 'package:dream_cast/app/widgets/adaptive_app_shell.dart';
import 'package:dream_cast/features/history/presentation/history_screen.dart';
import 'package:dream_cast/features/home/presentation/home_screen.dart';
import 'package:dream_cast/features/home/presentation/network_debug_screen.dart';
import 'package:dream_cast/features/library/presentation/library_screen.dart';
import 'package:dream_cast/features/onboarding/presentation/onboarding_screen.dart';
import 'package:dream_cast/features/onboarding/presentation/splash_screen.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/player/presentation/player_placeholder_screen.dart';
import 'package:dream_cast/features/player/presentation/video_player_screen.dart';
import 'package:dream_cast/features/profile/presentation/profile_screen.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/episode_list_screen.dart';
import 'package:dream_cast/features/releases/presentation/release_detail_screen.dart';
import 'package:dream_cast/features/releases/presentation/search_screen.dart';
import 'package:dream_cast/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _libraryNavigatorKey = GlobalKey<NavigatorState>();
final _historyNavigatorKey = GlobalKey<NavigatorState>();
final _settingsNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _fadeThroughPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdaptiveAppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => _fadeThroughPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => _fadeThroughPage(
                  key: state.pageKey,
                  child: const LibraryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => _fadeThroughPage(
                  key: state.pageKey,
                  child: const HistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _fadeThroughPage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _sharedAxisPage(
                      key: state.pageKey,
                      child: const ProfileScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _sharedAxisPage(key: state.pageKey, child: const SearchScreen()),
      ),
      GoRoute(
        path: '/network-debug',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const NetworkDebugScreen(),
        ),
      ),
      GoRoute(
        path: '/release/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final release = state.extra;
          return _sharedAxisPage(
            key: state.pageKey,
            child: release is DreamRelease
                ? ReleaseDetailScreen(release: release)
                : const _MissingRouteDataScreen(),
          );
        },
      ),
      GoRoute(
        path: '/episodes',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final detail = state.extra;
          return _sharedAxisPage(
            key: state.pageKey,
            child: detail is DreamReleaseDetail
                ? EpisodeListScreen(detail: detail)
                : const _MissingRouteDataScreen(),
          );
        },
      ),
      GoRoute(
        path: '/watch',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final request = state.extra;
          return _sharedAxisPage(
            key: state.pageKey,
            child: request is PlaybackRequest
                ? VideoPlayerScreen(request: request)
                : const _MissingRouteDataScreen(),
          );
        },
      ),
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _sharedAxisPage(
          key: state.pageKey,
          child: const PlayerPlaceholderScreen(),
        ),
      ),
    ],
  );
});

class _MissingRouteDataScreen extends StatelessWidget {
  const _MissingRouteDataScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Не удалось открыть')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Экран был открыт без данных релиза. Вернитесь назад и выберите релиз снова.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

Page<void> _fadeThroughPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

Page<void> _sharedAxisPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  );
}

import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/home/presentation/home_screen.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/release_list_state.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLatestReleasesController extends LatestReleasesController {
  FakeLatestReleasesController(this._initialState);

  final ReleaseListState _initialState;

  @override
  Future<ReleaseListState> build() async => _initialState;

  @override
  Future<void> refresh() async {}
}

void main() {
  const mockRelease1 = DreamRelease(
    id: 101,
    title: 'Похоже, сильнейшая профессия',
    originalTitle: 'The Strongest Profession',
    url: 'https://dreamerscast.com/releases/101',
    posterUrl: 'https://cache.dreamerscast.com/posters/101.webp',
    wallUrl: 'https://cache.dreamerscast.com/walls/101.webp',
    description: 'Описание тестового релиза.',
    currentEpisodes: 12,
    type: 'ТВ',
    year: 2026,
    status: 'Выходит',
  );

  const mockRelease2 = DreamRelease(
    id: 102,
    title: 'Копэн',
    originalTitle: 'Copen',
    url: 'https://dreamerscast.com/releases/102',
    posterUrl: 'https://cache.dreamerscast.com/posters/102.webp',
    wallUrl: 'https://cache.dreamerscast.com/walls/102.webp',
    description: 'Описание второго релиза.',
    currentEpisodes: 24,
    type: 'ТВ',
    year: 2025,
    status: 'Завершен',
  );

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Widget createTestWidget(ReleaseListState state) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        latestReleasesProvider.overrideWith(
          () => FakeLatestReleasesController(state),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('renders loading state with skeleton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.byType(ReleaseGridSkeleton), findsOneWidget);
      expect(find.textContaining('animetosho.xyz'), findsOneWidget);
    });

    testWidgets('renders empty state when provider returns 0 items', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const ReleaseListState.empty()));
      await tester.pumpAndSettle();

      expect(find.text('Релизы не найдены'), findsOneWidget);
      expect(find.text('Обновить'), findsOneWidget);
    });

    testWidgets('renders populated releases in grid view without diagnostics', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          const ReleaseListState(
            items: [mockRelease1, mockRelease2],
            totalCount: 2,
            page: 1,
            pageSize: 16,
            isStale: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ACTIVE'), findsNothing);
      expect(find.textContaining('Loaded'), findsNothing);
      expect(find.textContaining('ID:'), findsNothing);
      expect(find.textContaining('Info:'), findsNothing);
      expect(find.byType(ReleaseCard), findsNWidgets(2));
      expect(find.text('Похоже, сильнейшая профессия'), findsOneWidget);
      expect(find.text('Копэн'), findsOneWidget);
      expect(find.text('12 сер. • ТВ • 2026'), findsOneWidget);
      expect(find.text('24 сер. • ТВ • 2025'), findsOneWidget);
    });
  });
}

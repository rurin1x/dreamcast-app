import 'package:dream_cast/features/home/presentation/home_screen.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/release_list_state.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget createTestWidget(ReleaseListState state) {
    return ProviderScope(
      overrides: [
        latestReleasesProvider.overrideWith(
          () => FakeLatestReleasesController(state),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('renders loading state with skeleton and loader text', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: HomeScreen())),
      );

      // Verify header diagnostics is LOADING
      expect(
        find.textContaining('LOADING DATA FROM DREAM CAST'),
        findsOneWidget,
      );
      expect(find.text('Загрузка релизов с сервера...'), findsOneWidget);
    });

    testWidgets('renders empty state when provider returns 0 items', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const ReleaseListState.empty()));
      await tester.pumpAndSettle();

      // Verify custom Empty Container and button exist
      expect(find.text('СПИСОК РЕЛИЗОВ ПУСТ'), findsOneWidget);
      expect(find.text('Принудительно обновить'), findsOneWidget);
    });

    testWidgets('renders populated releases in grid view', (tester) async {
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

      // Verify diagnostics shows 2 items
      expect(find.textContaining('ACTIVE: Loaded 2 Releases'), findsOneWidget);

      // Verify custom cards are in the tree
      expect(find.byType(ReleaseCard), findsNWidgets(2));

      // Verify titles are completely visible and high-contrast
      expect(find.text('Похоже, сильнейшая профессия'), findsOneWidget);
      expect(find.text('Копэн'), findsOneWidget);

      // Verify ID debug overlay badges on the cards
      expect(find.text('ID: 101'), findsOneWidget);
      expect(find.text('ID: 102'), findsOneWidget);

      // Verify subtitle rendering custom info
      expect(find.text('Info: 12 сер. • ТВ • 2026'), findsOneWidget);
      expect(find.text('Info: 24 сер. • ТВ • 2025'), findsOneWidget);
    });
  });
}

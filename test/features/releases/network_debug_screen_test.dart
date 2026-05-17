import 'package:dream_cast/features/home/presentation/network_debug_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkDebugScreen Widget Tests', () {
    testWidgets('renders screen and all test trigger buttons correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NetworkDebugScreen(),
        ),
      );

      // Verify screen title exists
      expect(find.text('Сетевой отладчик (Dio Raw)'), findsOneWidget);

      // Verify the trigger buttons exist
      expect(find.text('Запустить все тесты связи'), findsOneWidget);
      expect(find.text('GET Google'), findsOneWidget);
      expect(find.text('GET DC Home'), findsOneWidget);
      expect(find.text('POST DC Search'), findsOneWidget);
      expect(find.text('GET CDN Image'), findsOneWidget);

      // Verify empty logs text is displayed initially
      expect(
        find.textContaining('Логи пусты. Запустите один или несколько тестов связи'),
        findsOneWidget,
      );
    });
  });
}

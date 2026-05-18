import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:flutter/material.dart';

class PlayerPlaceholderScreen extends StatelessWidget {
  const PlayerPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Проигрыватель',
      child: AppEmptyState(
        icon: Icons.play_circle_outline,
        title: 'Проигрыватель подготовлен',
        message:
            'Следующий этап улучшит Android-плеер, выбор качества и сохранение позиции.',
      ),
    );
  }
}

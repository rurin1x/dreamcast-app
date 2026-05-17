import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'История',
      child: AppEmptyState(
        icon: Icons.history_outlined,
        title: 'Пока ничего нет',
        message:
            'Когда начнёте просмотр, прогресс и последние серии будут отображаться здесь.',
      ),
    );
  }
}

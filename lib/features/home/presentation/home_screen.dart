import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Главная',
      actions: [
        IconButton(
          tooltip: 'Поиск',
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
      ],
      child: const AppEmptyState(
        icon: Icons.movie_filter_outlined,
        title: 'Основа готова',
        message:
            'Здесь появятся актуальные релизы Dream Cast после подключения экранов каталога.',
      ),
    );
  }
}

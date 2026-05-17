import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_screen.dart';
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Библиотека',
      child: AppEmptyState(
        icon: Icons.collections_bookmark_outlined,
        title: 'Библиотека пуста',
        message: 'Избранные релизы и сохранённые элементы появятся здесь.',
      ),
    );
  }
}

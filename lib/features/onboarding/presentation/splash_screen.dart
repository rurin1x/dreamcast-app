import 'package:dream_cast/app/widgets/app_loading_view.dart';
import 'package:dream_cast/core/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(appSettingsProvider).onboardingCompleted;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(completed ? '/home' : '/onboarding');
    });

    return const Scaffold(
      body: AppLoadingView(message: 'Подготовка приложения…'),
    );
  }
}

import 'package:flutter/material.dart';

class StaleCacheBanner extends StatelessWidget {
  const StaleCacheBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Показаны сохранённые данные. Обновление не удалось. Проверьте соединение или попробуйте включить VPN.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

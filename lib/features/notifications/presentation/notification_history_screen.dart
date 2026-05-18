import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history.dart';
import 'package:dream_cast/features/notifications/data/episode_notification_history_providers.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(episodeNotificationHistoryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(episodeNotificationHistoryProvider);
    final controller = ref.read(episodeNotificationHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            tooltip: 'Отметить прочитанными',
            onPressed: entries.any((entry) => !entry.isRead)
                ? controller.markAllRead
                : null,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Очистить',
            onPressed: entries.isNotEmpty ? controller.clearAll : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Уведомлений нет',
              message:
                  'Когда в подписанных тайтлах появятся новые серии, они будут отображаться здесь.',
            )
          : RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _NotificationTile(
                  entry: entries[index],
                  onTap: () async {
                    await controller.markRead(entries[index].id);
                    if (!context.mounted) return;
                    context.push(
                      '/release/${entries[index].release.id}',
                      extra: entries[index].release,
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry, required this.onTap});

  final EpisodeNotificationHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: entry.isRead
          ? theme.colorScheme.surfaceContainerLow
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: ClipOval(
                  child: ReleasePoster(
                    imageUrl: entry.release.posterUrl,
                    aspectRatio: 1,
                    borderRadius: 99,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.release.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!entry.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }
}

import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/core/settings/app_ui_preferences.dart';
import 'package:dream_cast/features/player/data/player_providers.dart';
import 'package:dream_cast/features/player/domain/playback_request.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/release_list_state.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_poster.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_skeletons.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(latestReleasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Cast'),
        actions: [
          IconButton(
            tooltip: 'Сетка релизов',
            onPressed: _showGridSettings,
            icon: const Icon(Icons.grid_view),
          ),
          IconButton(
            tooltip: 'Поиск',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SupportBanner(),
          Expanded(
            child: state.when(
              loading: () => const ReleaseGridSkeleton(),
              error: (error, stackTrace) => AppErrorView(
                error: error,
                onRetry: () =>
                    ref.read(latestReleasesProvider.notifier).refresh(),
              ),
              data: _buildContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReleaseListState data) {
    if (data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(latestReleasesProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 72),
            AppEmptyState(
              icon: Icons.movie_filter_outlined,
              title: 'Релизы не найдены',
              message:
                  'Попробуйте обновить страницу или проверить подключение.',
              action: FilledButton.icon(
                onPressed: () =>
                    ref.read(latestReleasesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(latestReleasesProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (data.isStale) const SliverToBoxAdapter(child: StaleCacheBanner()),
          const SliverToBoxAdapter(child: _ContinueWatchingSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'Последние обновления',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _ReleaseSliverGrid(releases: data.items, onTap: _openRelease),
          SliverToBoxAdapter(
            child: _LoadMoreFooter(
              isLoading: data.isLoadingMore,
              error: data.loadMoreError,
              hasMore: data.hasMore,
              onRetry: () =>
                  ref.read(latestReleasesProvider.notifier).loadMore(),
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 700) {
      ref.read(latestReleasesProvider.notifier).loadMore();
    }
  }

  void _openRelease(DreamRelease release) {
    context.push('/release/${release.id}', extra: release);
  }

  void _showGridSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _GridSettingsSheet(),
    );
  }
}

class _SupportBanner extends ConsumerWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appUiPreferencesProvider);
    if (prefs.isSupportBannerHidden) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              ref.read(appUiPreferencesProvider.notifier).hideSupportBanner(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Приложение создано благодаря фонду animetosho.xyz, приходите на наш торрент-трекер!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => ref
                      .read(appUiPreferencesProvider.notifier)
                      .hideSupportBanner(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridSettingsSheet extends ConsumerWidget {
  const _GridSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(appUiPreferencesProvider).homeGridColumns;
    final controller = ref.read(appUiPreferencesProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сетка релизов',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Выберите, сколько карточек показывать в одной строке.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 3,
                  icon: Icon(Icons.view_column_outlined),
                  label: Text('3'),
                ),
                ButtonSegment(
                  value: 4,
                  icon: Icon(Icons.grid_view),
                  label: Text('4'),
                ),
              ],
              selected: {columns},
              onSelectionChanged: (selection) {
                controller.setHomeGridColumns(selection.first);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseSliverGrid extends ConsumerWidget {
  const _ReleaseSliverGrid({required this.releases, required this.onTap});

  final List<DreamRelease> releases;
  final ValueChanged<DreamRelease> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossAxisCount = ref.watch(appUiPreferencesProvider).homeGridColumns;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      sliver: SliverGrid.builder(
        itemCount: releases.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 0.49,
        ),
        itemBuilder: (context, index) {
          final release = releases[index];
          return ReleaseCard(release: release, onTap: () => onTap(release));
        },
      ),
    );
  }
}

class _ContinueWatchingSection extends ConsumerWidget {
  const _ContinueWatchingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(continueWatchingProvider);

    return state.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text(
          'Не удалось загрузить прогресс просмотра',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Продолжить просмотр',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ContinueWatchingCard(
                      item: item,
                      onTap: () => _resume(context, ref, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resume(
    BuildContext context,
    WidgetRef ref,
    ContinueWatchingItem item,
  ) async {
    final request = await ref
        .read(playbackRepositoryProvider)
        .restorePlaybackRequest(item);
    if (!context.mounted) return;
    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось восстановить поток. Откройте серию из карточки релиза.',
          ),
        ),
      );
      return;
    }
    context.push('/watch', extra: request);
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item, required this.onTap});

  final ContinueWatchingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item.progress;
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.75,
    );

    return SizedBox(
      width: 268,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: ReleasePoster(
                    imageUrl: item.posterUrl,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.releaseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.episodeOrdinal} серия • ${_formatPosition(item.position)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (progress != null)
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(99),
                        )
                      else
                        Text(
                          'Прогресс сохранён',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      Icons.play_arrow,
                      size: 22,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPosition(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final bool isLoading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Загрузить ещё раз'),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Center(
          child: Text(
            'Это все релизы',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

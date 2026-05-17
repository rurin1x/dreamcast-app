import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_providers.dart';
import 'package:dream_cast/features/releases/presentation/release_list_state.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
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
            tooltip: 'Сеть',
            onPressed: () => context.push('/network-debug'),
            icon: const Icon(Icons.network_check),
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
          _DiagnosticsHeader(state: state),
          Expanded(
            child: state.when(
              loading: () => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Загрузка релизов с сервера...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: ReleaseGridSkeleton()),
                ],
              ),
              error: (error, stackTrace) => AppErrorView(
                error: error,
                onRetry: () => ref.read(latestReleasesProvider.notifier).refresh(),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(latestReleasesProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.warning_amber_outlined,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'СПИСОК РЕЛИЗОВ ПУСТ',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Провайдер успешно вернул пустой список. Возможно, кэш пуст или возникла сетевая ошибка.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        AppEmptyState(
                          icon: Icons.movie_filter_outlined,
                          title: 'Релизы не найдены',
                          message:
                              'Попробуйте обновить страницу или проверить подключение.',
                          action: FilledButton.icon(
                            onPressed: () =>
                                ref.read(latestReleasesProvider.notifier).refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Принудительно обновить'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(latestReleasesProvider.notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (data.isStale)
                        const SliverToBoxAdapter(child: StaleCacheBanner()),
                      const SliverToBoxAdapter(child: _ContinueWatchingSection()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Text(
                            'Последние обновления',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 700) {
      ref.read(latestReleasesProvider.notifier).loadMore();
    }
  }

  void _openRelease(DreamRelease release) {
    context.push('/release/${release.id}', extra: release);
  }
}

class _DiagnosticsHeader extends StatelessWidget {
  const _DiagnosticsHeader({required this.state});

  final AsyncValue<ReleaseListState> state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = state.when(
      loading: () => Colors.blue.shade900,
      error: (_, __) => Colors.red.shade900,
      data: (_) => Colors.green.shade900,
    );
    final statusBg = state.when(
      loading: () => Colors.blue.shade50,
      error: (_, __) => Colors.red.shade50,
      data: (_) => Colors.green.shade50,
    );
    final statusLabel = state.when(
      loading: () => '🔄 LOADING DATA FROM DREAM CAST',
      error: (err, _) => '❌ ERROR: $err',
      data: (data) => '✅ ACTIVE: Loaded ${data.items.length} Releases',
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  state.when(
                    loading: () => 'WAIT',
                    error: (_, __) => 'FAIL',
                    data: (data) => data.isStale ? 'CACHE' : 'LIVE',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Provider: latestReleasesProvider • Parser: DreamCastHtmlParser • CDN: cache.dreamerscast.com',
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor.withOpacity(0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseSliverGrid extends StatelessWidget {
  const _ReleaseSliverGrid({required this.releases, required this.onTap});

  final List<DreamRelease> releases;
  final ValueChanged<DreamRelease> onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = switch (width) {
      < 420 => 3,
      < 700 => 4,
      < 1000 => 5,
      _ => 6,
    };

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

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(Icons.play_circle_outline),
          title: const Text('Продолжить просмотр'),
          subtitle: const Text(
            'Здесь появятся серии после первого запуска проигрывателя.',
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
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

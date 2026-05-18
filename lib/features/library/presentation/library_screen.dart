import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/features/library/data/release_bookmark_providers.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const _previewLimit = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(libraryBookmarksProvider);
    final grouped = _groupByStatus(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      body: entries.isEmpty
          ? const AppEmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'Библиотека пуста',
              message:
                  'Добавьте тайтлы в закладки на странице релиза, и они появятся здесь.',
            )
          : CustomScrollView(
              slivers: [
                for (final status in ReleaseBookmarkStatus.values)
                  if (grouped[status]?.isNotEmpty == true)
                    SliverToBoxAdapter(
                      child: _LibraryStatusSection(
                        status: status,
                        entries: grouped[status]!,
                        previewLimit: _previewLimit,
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Map<ReleaseBookmarkStatus, List<ReleaseBookmarkEntry>> _groupByStatus(
    List<ReleaseBookmarkEntry> entries,
  ) {
    return {
      for (final status in ReleaseBookmarkStatus.values)
        status: entries.where((entry) => entry.status == status).toList(),
    };
  }
}

class LibraryStatusScreen extends ConsumerWidget {
  const LibraryStatusScreen({required this.status, super.key});

  final ReleaseBookmarkStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(libraryBookmarksProvider)
        .where((entry) => entry.status == status)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(status.label)),
      body: entries.isEmpty
          ? AppEmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: 'Здесь пока пусто',
              message: 'В разделе «${status.label}» ещё нет тайтлов.',
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
                  sliver: SliverGrid.builder(
                    itemCount: entries.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridColumns(context),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.49,
                    ),
                    itemBuilder: (context, index) {
                      final release = entries[index].release;
                      return ReleaseCard(
                        release: release,
                        onTap: () => _openRelease(context, release),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 6;
    if (width >= 600) return 4;
    return 3;
  }
}

class _LibraryStatusSection extends StatelessWidget {
  const _LibraryStatusSection({
    required this.status,
    required this.entries,
    required this.previewLimit,
  });

  final ReleaseBookmarkStatus status;
  final List<ReleaseBookmarkEntry> entries;
  final int previewLimit;

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(previewLimit).toList(growable: false);
    final shouldShowAll = entries.length > previewLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LibraryStatusStrip(
              status: status,
              count: entries.length,
              onShowAll: () => _openStatus(context, status),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 224,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: visible.length + (shouldShowAll ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == visible.length) {
                  return _ShowAllCard(
                    label: 'Показать все',
                    onTap: () => _openStatus(context, status),
                  );
                }
                final release = visible[index].release;
                return SizedBox(
                  width: _cardWidth(context),
                  child: ReleaseCard(
                    release: release,
                    onTap: () => _openRelease(context, release),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _cardWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 132;
    if (width >= 600) return 122;
    return 112;
  }
}

class _LibraryStatusStrip extends StatelessWidget {
  const _LibraryStatusStrip({
    required this.status,
    required this.count,
    required this.onShowAll,
  });

  final ReleaseBookmarkStatus status;
  final int count;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: onShowAll, child: const Text('Показать все')),
          ],
        ),
      ),
    );
  }
}

class _ShowAllCard extends StatelessWidget {
  const _ShowAllCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 112,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openStatus(BuildContext context, ReleaseBookmarkStatus status) {
  context.push('/library/status/${status.name}');
}

void _openRelease(BuildContext context, DreamRelease release) {
  context.push('/release/${release.id}', extra: release);
}

ReleaseBookmarkStatus? libraryStatusFromName(String? name) {
  return switch (name) {
    'watching' => ReleaseBookmarkStatus.watching,
    'completed' => ReleaseBookmarkStatus.completed,
    'dropped' => ReleaseBookmarkStatus.dropped,
    'planned' => ReleaseBookmarkStatus.planned,
    _ => null,
  };
}

import 'package:dream_cast/app/widgets/app_empty_state.dart';
import 'package:dream_cast/app/widgets/app_error_view.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_skeletons.dart';
import 'package:dream_cast/features/releases/presentation/widgets/stale_cache_banner.dart';
import 'package:dream_cast/features/schedule/data/schedule_providers.dart';
import 'package:dream_cast/features/schedule/domain/release_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(releaseScheduleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      body: state.when(
        loading: () => const ReleaseGridSkeleton(),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(releaseScheduleProvider),
        ),
        data: (data) {
          final schedule = data.value;
          if (schedule.days.every((day) => day.releases.isEmpty)) {
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Расписание пустое',
                    message: 'Пока нет релизов в календаре.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (data.isStale)
                  const SliverToBoxAdapter(child: StaleCacheBanner()),
                for (final day in schedule.days)
                  SliverToBoxAdapter(
                    child: _ScheduleDaySection(
                      day: day,
                      onTap: (release) => context.push(
                        '/release/${release.id}',
                        extra: release,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final refreshed = ref.refresh(releaseScheduleProvider.future);
    await refreshed;
  }
}

class _ScheduleDaySection extends StatelessWidget {
  const _ScheduleDaySection({required this.day, required this.onTap});

  final ReleaseScheduleDay day;
  final ValueChanged<DreamRelease> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 840
        ? 132.0
        : width >= 600
        ? 122.0
        : 112.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DayStrip(day: day),
          ),
          const SizedBox(height: 8),
          if (day.releases.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
              child: Text(
                'На этот день релизов нет.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: day.releases.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final release = day.releases[index];
                  return SizedBox(
                    width: cardWidth,
                    child: ReleaseCard(
                      release: release,
                      onTap: () => onTap(release),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.day});

  final ReleaseScheduleDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                day.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                child: Text(
                  '${day.releases.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                for (final day in schedule.days) ...[
                  SliverToBoxAdapter(child: _DayHeader(day: day)),
                  if (day.releases.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
                        child: Text('На этот день релизов нет.'),
                      ),
                    )
                  else
                    _ScheduleGrid(
                      releases: day.releases,
                      onTap: (release) => context.push(
                        '/release/${release.id}',
                        extra: release,
                      ),
                    ),
                ],
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final ReleaseScheduleDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Text(
            day.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${day.releases.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.releases, required this.onTap});

  final List<DreamRelease> releases;
  final ValueChanged<DreamRelease> onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 840
        ? 6
        : width >= 600
        ? 4
        : 3;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
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

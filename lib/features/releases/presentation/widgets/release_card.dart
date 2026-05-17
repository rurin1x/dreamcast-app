import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_poster.dart';
import 'package:flutter/material.dart';

class ReleaseCard extends StatelessWidget {
  const ReleaseCard({required this.release, required this.onTap, super.key});

  final DreamRelease release;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ReleasePoster(imageUrl: release.posterUrl)),
            const SizedBox(height: 6),
            Text(
              release.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = [
      if (release.currentEpisodes != null) '${release.currentEpisodes} сер.',
      if (release.type != null && release.type!.trim().isNotEmpty)
        release.type!,
      if (release.year != null) '${release.year}',
    ];
    return parts.isEmpty ? 'Dream Cast' : parts.join(' • ');
  }
}

class ReleaseListTile extends StatelessWidget {
  const ReleaseListTile({
    required this.release,
    required this.onTap,
    super.key,
  });

  final DreamRelease release;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        child: ReleasePoster(imageUrl: release.posterUrl, borderRadius: 8),
      ),
      title: Text(release.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (release.currentEpisodes != null)
            '${release.currentEpisodes} серий',
          if (release.status != null) release.status!,
          if (release.rating != null) '★ ${release.rating}',
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

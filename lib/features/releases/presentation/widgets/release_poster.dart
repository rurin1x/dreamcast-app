import 'package:cached_network_image/cached_network_image.dart';
import 'package:dream_cast/core/utils/url_normalizer.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:flutter/material.dart';

class ReleasePoster extends StatelessWidget {
  const ReleasePoster({
    required this.imageUrl,
    this.aspectRatio = 2 / 3,
    this.borderRadius = 10,
    super.key,
  });

  final String? imageUrl;
  final double aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedUrl = normalizeDreamCastImageUrl(imageUrl);
    final valid = isValidHttpUrl(normalizedUrl);
    if (imageUrl != null && imageUrl!.isNotEmpty && !valid) {
      logDreamCastDiagnostic(
        'Poster invalid URL: raw="$imageUrl", normalized="$normalizedUrl"',
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: normalizedUrl == null || !valid
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_outlined,
                      color: theme.colorScheme.error,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        normalizedUrl == null ? 'NULL URL' : 'INVALID URL',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              : CachedNetworkImage(
                  imageUrl: normalizedUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 160),
                  fadeOutDuration: const Duration(milliseconds: 80),
                  placeholder: (context, url) => const _PosterPlaceholder(),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.errorContainer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onErrorContainer,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'LOAD ERROR',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  errorListener: (error) {
                    logDreamCastDiagnostic(
                      'Poster load failed: url="$normalizedUrl", error=$error',
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

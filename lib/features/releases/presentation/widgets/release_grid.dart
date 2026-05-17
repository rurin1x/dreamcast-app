import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/widgets/release_card.dart';
import 'package:flutter/material.dart';

class ReleaseGrid extends StatelessWidget {
  const ReleaseGrid({
    required this.releases,
    required this.onReleaseTap,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(10, 8, 10, 24),
    this.footer,
    super.key,
  });

  final List<DreamRelease> releases;
  final ValueChanged<DreamRelease> onReleaseTap;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = switch (width) {
      < 420 => 3,
      < 700 => 4,
      < 1000 => 5,
      _ => 6,
    };
    final itemCount = releases.length + (footer == null ? 0 : 1);

    return GridView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 6,
        childAspectRatio: 0.49,
      ),
      itemBuilder: (context, index) {
        if (index >= releases.length) {
          return Center(child: footer);
        }
        final release = releases[index];
        return ReleaseCard(
          release: release,
          onTap: () => onReleaseTap(release),
        );
      },
    );
  }
}

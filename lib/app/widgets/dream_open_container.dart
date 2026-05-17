import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class DreamOpenContainer extends StatelessWidget {
  const DreamOpenContainer({
    required this.closedBuilder,
    required this.openBuilder,
    super.key,
  });

  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder openBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 320),
      closedColor: Colors.transparent,
      openColor: scheme.surface,
      middleColor: scheme.surfaceContainerHighest,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      closedBuilder: closedBuilder,
      openBuilder: openBuilder,
    );
  }
}

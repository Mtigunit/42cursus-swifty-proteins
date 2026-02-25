import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({required this.context, super.key});

  // ignore: avoid_unused_constructor_parameters — kept for explicit context access pattern.
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final textTheme = Theme.of(ctx).textTheme;
    return Column(
      children: [
        Text(
          'Swifty Proteins',
          style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '3D Molecular Visualization',
          style: textTheme.bodyMedium?.copyWith(
            color: textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

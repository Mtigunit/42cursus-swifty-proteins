import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.2),
            primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: child,
    );
  }
}

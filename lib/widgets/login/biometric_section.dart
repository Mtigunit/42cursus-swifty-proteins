import 'package:flutter/material.dart';

class BiometricSection extends StatelessWidget {
  const BiometricSection({
    required this.available,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool available;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (available) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.fingerprint),
        label: const Text('Biometric Login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Biometric authentication is not available on this device.',
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

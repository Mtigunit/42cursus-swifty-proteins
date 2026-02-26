import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.login),
        label: Text(isLoading ? 'Logging in…' : 'Login'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
  }
}

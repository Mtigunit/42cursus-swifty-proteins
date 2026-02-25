import 'package:flutter/material.dart';
import 'package:swifty_proteins/widgets/common/app_title.dart';
import 'package:swifty_proteins/widgets/common/error_dialog.dart';
import 'package:swifty_proteins/widgets/common/gradient_background.dart';
import 'package:swifty_proteins/widgets/login/login_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onBiometricLogin,
    this.onPasswordLogin,
    this.biometricAvailable = false,
  });

  final VoidCallback? onBiometricLogin;
  final void Function(String username, String password)? onPasswordLogin;
  final bool biometricAvailable;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────
  void _handlePasswordLogin() {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter both a username and password.');
      return;
    }

    setState(() => _isLoading = true);
    widget.onPasswordLogin?.call(username, password);
  }

  void stopLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        title: 'Login Failed',
        message: message,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardVisible =
                  MediaQuery.viewInsetsOf(context).bottom > 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: keyboardVisible
                              ? 20
                              : constraints.maxHeight * 0.1,
                        ),
                        if (!keyboardVisible) ...[
                          const AppIcon(),
                          const SizedBox(height: 24),
                        ],
                        AppTitle(context: context),
                        const SizedBox(height: 40),
                        LoginForm(
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          usernameFocus: _usernameFocus,
                          passwordFocus: _passwordFocus,
                          obscurePassword: _obscurePassword,
                          isLoading: _isLoading,
                          onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onSubmit: _handlePasswordLogin,
                        ),
                        const SizedBox(height: 32),
                        LoginButton(
                          isLoading: _isLoading,
                          onPressed: _handlePasswordLogin,
                        ),
                        const SizedBox(height: 16),
                        const OrDivider(),
                        const SizedBox(height: 16),
                        BiometricSection(
                          available: widget.biometricAvailable,
                          isLoading: _isLoading,
                          onPressed: widget.onBiometricLogin,
                        ),
                        const Spacer(),
                        const Footer(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

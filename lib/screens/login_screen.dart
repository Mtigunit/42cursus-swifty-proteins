import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swifty_proteins/services/auth_service.dart';
import 'package:swifty_proteins/widgets/common/app_title.dart';
import 'package:swifty_proteins/widgets/common/gradient_background.dart';
import 'package:swifty_proteins/widgets/login/login_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _secureStorage = const FlutterSecureStorage();
  bool _hasPreviousSession = false;

  @override
  void initState() {
    super.initState();
    _checkPreviousSession();
    _authService.checkBiometricAvailability();
  }

  Future<void> _checkPreviousSession() async {
    final email = await _secureStorage.read(key: "email");

    if (mounted) {
      setState(() => _hasPreviousSession = email != null);
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: ListenableBuilder(
                      listenable: _authService,
                      builder: (context, _) {
                        return Column(
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
                              authService: _authService,
                              onSubmit: () => _authService.onSignIn(context),
                              isBiometricLoading:
                                  _authService.isBiometricLoading,
                            ),
                            const SizedBox(height: 16),
                            if (_hasPreviousSession) ...[
                              const OrDivider(),
                              const SizedBox(height: 16),
                              BiometricSection(
                                available: _authService.isBiometricAvailable,
                                isLoading: _authService.isBiometricLoading,
                                isDisabled: _authService.isLoginLoading,
                                onPressed: () => _authService
                                    .authenticateWithBiometrics(context),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Spacer(),
                            const Footer(),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
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

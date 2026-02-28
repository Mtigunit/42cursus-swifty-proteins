import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swifty_proteins/services/auth_service.dart';
import 'package:swifty_proteins/widgets/common/app_title.dart';
import 'package:swifty_proteins/widgets/common/error_dialog.dart';
import 'package:swifty_proteins/widgets/common/gradient_background.dart';
import 'package:swifty_proteins/widgets/login/login_widgets.dart';

/// Login screen that handles user authentication via email/password and biometrics
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Layout constants
  static const double _horizontalPadding = 24.0;
  static const double _topSpacingCollapsed = 20.0;
  static const double _topSpacingExpandedRatio = 0.1;
  static const double _iconSpacing = 24.0;
  static const double _formSpacing = 40.0;
  static const double _sectionSpacing = 16.0;
  static const double _bottomSpacing = 32.0;
  static const String _emailStorageKey = 'email';

  // Services
  final _authService = AuthService();
  final _secureStorage = const FlutterSecureStorage();

  // State
  bool _hasPreviousSession = false;
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeScreen();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  /// Initialize screen by checking for previous session and biometric availability
  Future<void> _initializeScreen() async {
    await Future.wait([
      _checkForPreviousSession(),
      _authService.checkBiometricAvailability(),
    ]);
  }

  /// Check if user has previously logged in by verifying stored credentials
  Future<void> _checkForPreviousSession() async {
    final storedEmail = await _secureStorage.read(key: _emailStorageKey);
    if (mounted) {
      setState(() {
        _hasPreviousSession = storedEmail != null && storedEmail.isNotEmpty;
      });
    }
  }

  /// Determine if keyboard is currently visible
  bool _isKeyboardVisible(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  /// Calculate top spacing based on keyboard visibility
  double _calculateTopSpacing(bool isKeyboardVisible, double maxHeight) {
    return isKeyboardVisible
        ? _topSpacingCollapsed
        : maxHeight * _topSpacingExpandedRatio;
  }

  /// Handle sign-in action
  void _handleSignIn() {
    _authService.onSignIn(context);
  }

  /// Handle biometric authentication
  void _handleBiometricAuth() {
    _authService.authenticateWithBiometrics(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GradientBackground(
        child: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            // Show loading indicator during initialization
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle initialization errors
            if (snapshot.hasError) {
              return ErrorDialog(
                title: "Initialization Error",
                message:
                    "An error occurred while initializing the login screen. Please try restarting the app.",
                onDismiss: () => exit(1),
              );
            }
            return _buildLoginContent();
          },
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardVisible = _isKeyboardVisible(context);
          final topSpacing = _calculateTopSpacing(
            isKeyboardVisible,
            constraints.maxHeight,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: ListenableBuilder(
                  listenable: _authService,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topSpacing),
                      if (!isKeyboardVisible) ...[
                        const AppIcon(),
                        const SizedBox(height: _iconSpacing),
                      ],
                      AppTitle(context: context),
                      const SizedBox(height: _formSpacing),
                      _buildLoginForm(),
                      const SizedBox(height: _sectionSpacing),
                      if (_hasPreviousSession) ..._buildBiometricSection(),
                      const Spacer(),
                      const Footer(),
                      const SizedBox(height: _bottomSpacing),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return LoginForm(
      authService: _authService,
      onSubmit: _handleSignIn,
      isBiometricLoading: _authService.isBiometricLoading,
    );
  }

  List<Widget> _buildBiometricSection() {
    return [
      const OrDivider(),
      const SizedBox(height: _sectionSpacing),
      BiometricSection(
        available: _authService.isBiometricAvailable,
        isLoading: _authService.isBiometricLoading,
        isDisabled: _authService.isLoginLoading,
        onPressed: _handleBiometricAuth,
      ),
      const SizedBox(height: _sectionSpacing),
    ];
  }
}

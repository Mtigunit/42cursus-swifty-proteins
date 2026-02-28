import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swifty_proteins/navigation/app_navigator.dart';
import 'package:swifty_proteins/widgets/common/gradient_background.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:swifty_proteins/widgets/common/app_title.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashMinDuration = Duration(milliseconds: 2000);
  static const _animationDuration = Duration(milliseconds: 1000);
  static const _transitionDuration = Duration(milliseconds: 1000);
  static const _logoAsset = 'assets/splash/splash_logo.png';
  static const _logoSize = 90.0;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _setupAnimations();
    _controller.forward();
    Timer(_splashMinDuration, _navigateToMain);
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_buildTransitionRoute());
  }

  PageRouteBuilder _buildTransitionRoute() {
    return PageRouteBuilder(
      transitionDuration: _transitionDuration,
      pageBuilder: (_, _, _) => const AppNavigator(),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _SplashContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'App logo',
          image: true,
          child: Image.asset(
            _SplashScreenState._logoAsset,
            width: _SplashScreenState._logoSize,
            height: _SplashScreenState._logoSize,
          ),
        ),
        const SizedBox(height: 40),
        AppTitle(context: context),
        const SizedBox(height: 40),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:swifty_proteins/navigation/app_navigator.dart';
import 'utils/theme.dart' as app_theme;

class SwiftyProteinsApp extends StatelessWidget {
  const SwiftyProteinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swifty Proteins',
      theme: app_theme.SwiftyTheme.lightTheme,
      darkTheme: app_theme.SwiftyTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

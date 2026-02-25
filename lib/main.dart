import 'package:flutter/material.dart';
import 'package:swifty_proteins/app.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  // Preserve the native splash screen until Flutter is ready
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const SwiftyProteinsApp());
}

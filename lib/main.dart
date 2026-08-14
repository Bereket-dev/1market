import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/service_bootstrap.dart';
import 'core/errors/error_reporter.dart';
import 'shared/widgets/app_error_widget.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global Flutter framework errors.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ErrorReporter.recordError(
        details.exception,
        details.stack,
        fatal: true,
        reason: details.context?.toString(),
      );
    };

    // Uncaught async / platform errors.
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorReporter.recordError(error, stack, fatal: true);
      return true;
    };

    // Calm ErrorWidget instead of the red screen (release).
    ErrorWidget.builder = (details) => AppErrorWidget(details: details);

    registerFcmBackgroundHandler();

    bool initialDarkMode = false;
    String initialLocale = 'en';
    try {
      final prefs = await SharedPreferences.getInstance();
      initialDarkMode = prefs.getBool('koolan_dark_mode') ?? false;
      initialLocale = prefs.getString('koolan_language') ?? 'en';
    } catch (_) {
      // SharedPreferences unavailable — use defaults.
    }

    final bootstrap = await ServiceBootstrap.initialize();

    runApp(KoolanApp(
      initialDarkMode: initialDarkMode,
      initialLocale: initialLocale,
      bootstrapErrorCode: bootstrap.ok ? null : bootstrap.errorCode,
    ));
  }, (error, stack) {
    ErrorReporter.recordError(error, stack, fatal: true);
  });
}

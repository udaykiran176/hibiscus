import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hibiscus/src/rust/api/init.dart' as init_api;

enum AppLogLevel { trace, debug, info, warn, error }

class AppLogger {
  static bool _installed = false;

  static void installGlobalHandlers() {
    if (_installed) return;
    _installed = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      final stack = details.stack ?? StackTrace.current;
      error('flutter', details.exceptionAsString(), stack: stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('platform', error.toString(), stack: stack);
      return false;
    };
  }

  static void trace(String tag, String message, {StackTrace? stack}) =>
      _log(AppLogLevel.trace, tag, message, stack: stack);

  static void debug(String tag, String message, {StackTrace? stack}) =>
      _log(AppLogLevel.debug, tag, message, stack: stack);

  static void info(String tag, String message, {StackTrace? stack}) =>
      _log(AppLogLevel.info, tag, message, stack: stack);

  static void warn(String tag, String message, {StackTrace? stack}) =>
      _log(AppLogLevel.warn, tag, message, stack: stack);

  static void error(String tag, String message, {StackTrace? stack}) =>
      _log(AppLogLevel.error, tag, message, stack: stack);

  static void _log(
    AppLogLevel level,
    String tag,
    String message, {
    StackTrace? stack,
  }) {
    unawaited(_send(level, tag, message, stack: stack));
  }

  static Future<void> _send(
    AppLogLevel level,
    String tag,
    String message, {
    StackTrace? stack,
  }) async {
    try {
      await init_api.reportFlutterLog(
        level: level.name,
        message: message,
        tag: tag,
        stack: stack?.toString(),
      );
    } catch (_) {
      // Ignore logging failures to avoid recursive errors.
    }
  }
}

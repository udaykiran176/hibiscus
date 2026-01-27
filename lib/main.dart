import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:hibiscus/src/rust/frb_generated.dart';
import 'package:hibiscus/src/rust/api/init.dart' as init_api;
import 'package:hibiscus/src/router/router.dart';
import 'package:hibiscus/src/ui/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hibiscus/src/state/user_state.dart';
import 'package:hibiscus/src/state/settings_state.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hibiscus/src/services/app_logger.dart';
import 'package:hibiscus/src/services/webdav_sync_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 初始化 Rust 库
      await RustLib.init();
      final appSupportDir = await getApplicationSupportDirectory();
      debugPrint('App Support Directory: ${appSupportDir.path}');
      await init_api.initApp(dataPath: appSupportDir.path);
      AppLogger.installGlobalHandlers();
      await userState.checkLoginStatus();
      await settingsState.init();

      MediaKit.ensureInitialized();

      runApp(const HibiscusApp());
    },
    (error, stack) => AppLogger.error('zone', error.toString(), stack: stack),
  );
}

class HibiscusApp extends StatelessWidget {
  const HibiscusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final mode = settingsState.settings.value.themeMode;
      return MaterialApp(
        title: 'Hibiscus',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        initialRoute: AppRoutes.home,
        onGenerateRoute: onGenerateRoute,
        builder: (context, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WebDavSyncService.autoSyncOnAppStart(context: context);
          });
          return child ?? const SizedBox.shrink();
        },
      );
    });
  }
}

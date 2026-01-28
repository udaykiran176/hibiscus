import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const AppEntry());
    },
    (error, stack) => AppLogger.error('zone', error.toString(), stack: stack),
  );
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await RustLib.init();
    final appSupportDir = await getApplicationSupportDirectory();
    debugPrint('App Support Directory: ${appSupportDir.path}');
    await init_api.initApp(dataPath: appSupportDir.path);
    AppLogger.installGlobalHandlers();
    await userState.checkLoginStatus();
    await settingsState.init();
    MediaKit.ensureInitialized();
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const InitializationPage();
    }
    return const HibiscusApp();
  }
}

class InitializationPage extends StatelessWidget {
  const InitializationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hibiscus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('Hibiscus')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              SvgPicture.asset(
                'assets/images/android_adaptive_foreground.svg',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 12),
              const Text('正在初始化...'),
            ],
          ),
        ),
      ),
    );
  }
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

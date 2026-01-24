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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Rust 库
  await RustLib.init();
  final appSupportDir = await getApplicationSupportDirectory();
  await init_api.initApp(dataPath: appSupportDir.path);
  await userState.checkLoginStatus();
  await settingsState.init();
  
  MediaKit.ensureInitialized();
  
  runApp(const HibiscusApp());
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
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        initialRoute: AppRoutes.home,
        onGenerateRoute: onGenerateRoute,
      );
    });
  }
}

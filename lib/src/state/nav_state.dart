// 导航状态（用于在布局切换时保持当前 Tab）

import 'package:signals/signals_flutter.dart';

class AppNavState {
  static final AppNavState _instance = AppNavState._();
  factory AppNavState() => _instance;
  AppNavState._();

  // 默认打开“发现”
  final selectedIndex = signal<int>(2);

  void setIndex(int index) {
    if (index < 0) return;
    selectedIndex.value = index;
  }
}

final appNavState = AppNavState();

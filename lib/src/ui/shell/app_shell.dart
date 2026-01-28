// App Shell - 包含自适应导航的布局容器
// 手机：底部导航栏 (BottomNavigationBar)
// 平板：侧边导航栏 (NavigationRail)
// 桌面：常驻侧栏 (NavigationDrawer)

import 'package:flutter/material.dart';
import 'package:hibiscus/src/router/router.dart';
import 'package:hibiscus/src/ui/theme/app_theme.dart';
import 'package:hibiscus/src/ui/pages/home_page.dart';
import 'package:hibiscus/src/ui/pages/history_page.dart';
import 'package:hibiscus/src/ui/pages/downloads_page.dart';
import 'package:hibiscus/src/ui/pages/subscriptions_page.dart';
import 'package:hibiscus/src/ui/pages/settings_page.dart';
import 'package:hibiscus/src/state/nav_state.dart';
import 'package:hibiscus/src/state/settings_state.dart';
import 'package:signals/signals_flutter.dart';

/// 导航项配置
class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

/// 导航项（所有布局共用）
const _destinations = [
  _NavDestination(
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: '历史',
    route: AppRoutes.history,
  ),
  _NavDestination(
    icon: Icons.subscriptions_outlined,
    selectedIcon: Icons.subscriptions,
    label: '订阅',
    route: AppRoutes.subscriptions,
  ),
  _NavDestination(
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    label: '发现',
    route: AppRoutes.home,
  ),
  _NavDestination(
    icon: Icons.download_outlined,
    selectedIcon: Icons.download,
    label: '下载',
    route: AppRoutes.downloads,
  ),
  _NavDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: '设置',
    route: AppRoutes.settings,
  ),
];

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = appNavState.selectedIndex.value;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index, List<_NavDestination> destinations) {
    appNavState.setIndex(index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Watch 监听 appNavState 的变化，确保点击导航项时 UI 自动更新
    return Watch((context) {
      // 始终使用 appNavState 中的当前索引，确保布局切换时保持正确的页面
      final currentIndex = appNavState.selectedIndex.value;
      final navigationType = settingsState.settings.value.navigationType;

      // 确保 PageController 与当前索引同步（布局切换时）
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round();
        if (currentPage != null && currentPage != currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(currentIndex);
            }
          });
        }
      }

      final isDesktop = Breakpoints.isDesktop(context);
      final isTablet = Breakpoints.isTablet(context);

      if (navigationType == NavigationType.bottom) {
        return _buildMobileLayout(currentIndex);
      }

      if (navigationType == NavigationType.sidebar) {
        return _buildTabletLayout(currentIndex);
      }

      // 自适应（Adaptive）
      if (isDesktop || isTablet) {
        return _buildTabletLayout(currentIndex);
      }

      return _buildMobileLayout(currentIndex);
    });
  }

  /// 平板布局：NavigationRail
  Widget _buildTabletLayout(int selectedIndex) {
    return Row(
      key: Key("MAIN_ROW"),
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _onDestinationSelected(index, _destinations),
          labelType: NavigationRailLabelType.all,
          destinations: _destinations.map((dest) {
            return NavigationRailDestination(
              icon: Icon(dest.icon),
              selectedIcon: Icon(dest.selectedIcon),
              label: Text(dest.label),
            );
          }).toList(),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: Scaffold(key: Key("MAIN_SCAFFOLD"), body: _buildPageView()),
        ),
      ],
    );
  }

  /// 手机布局：底部导航栏
  Widget _buildMobileLayout(int selectedIndex) {
    return Row(
      key: Key("MAIN_ROW"),
      children: [
        Expanded(
          child: Scaffold(
            key: Key("MAIN_SCAFFOLD"),
            body: _buildPageView(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(index, _destinations),
              destinations: _destinations.map((dest) {
                return NavigationDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: dest.label,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageView() {
    return PageView(
      key: Key("MAIN_PAGEVIEW"),
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        HistoryPage(),
        SubscriptionsPage(),
        HomePage(),
        DownloadsPage(),
        SettingsPage(),
      ],
    );
  }
}

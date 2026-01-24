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
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = appNavState.selectedIndex.value;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  int _getSelectedIndex(String location, List<_NavDestination> destinations) {
    for (int i = 0; i < destinations.length; i++) {
      if (location == destinations[i].route || 
          (destinations[i].route == AppRoutes.home && location == '/')) {
        return i;
      }
    }
    return 0;
  }
  
  void _onDestinationSelected(int index, List<_NavDestination> destinations) {
    setState(() => _pageIndex = index);
    appNavState.setIndex(index);
    _pageController.jumpToPage(index);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final isTablet = Breakpoints.isTablet(context);
    final location = _destinations[_pageIndex].route;
    
    // 桌面端：常驻侧栏 (NavigationDrawer 样式)
    if (isDesktop) {
      return _buildDesktopLayout(location);
    }
    
    // 平板：NavigationRail
    if (isTablet) {
      return _buildTabletLayout(location);
    }
    
    // 手机：底部导航栏
    return _buildMobileLayout(location);
  }
  
  /// 桌面端布局：常驻宽侧栏
  Widget _buildDesktopLayout(String location) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedIndex = _getSelectedIndex(location, _destinations);
    
    return Row(
      children: [
        // 常驻侧栏
        SizedBox(
          width: 280,
          child: Material(
            color: colorScheme.surface,
            child: SafeArea(
              child: Column(
                children: [
                  // Logo / 标题区域
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_florist,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Hibiscus',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 导航项
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _destinations.length,
                      itemBuilder: (context, index) {
                        final dest = _destinations[index];
                        final isSelected = index == selectedIndex;
                        
                        // 在设置项前添加分隔线
                        if (dest.route == AppRoutes.settings) {
                          return Column(
                            children: [
                              const Divider(height: 16),
                              _buildNavTile(dest, isSelected, index),
                            ],
                          );
                        }
                        
                        return _buildNavTile(dest, isSelected, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // 主内容
        Expanded(child: _buildPageView()),
      ],
    );
  }
  
  /// 导航列表项
  Widget _buildNavTile(_NavDestination dest, bool isSelected, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          isSelected ? dest.selectedIcon : dest.icon,
          color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          dest.label,
          style: TextStyle(
            color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
                        onTap: () => _onDestinationSelected(index, _destinations),
      ),
    );
  }
  
  /// 平板布局：NavigationRail
  Widget _buildTabletLayout(String location) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedIndex = _getSelectedIndex(location, _destinations);
    
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onDestinationSelected(index, _destinations),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(
              Icons.local_florist,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          destinations: _destinations.map((dest) {
            return NavigationRailDestination(
              icon: Icon(dest.icon),
              selectedIcon: Icon(dest.selectedIcon),
              label: Text(dest.label),
            );
          }).toList(),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildPageView()),
      ],
    );
  }
  
  /// 手机布局：底部导航栏
  Widget _buildMobileLayout(String location) {
    final selectedIndex = _getSelectedIndex(location, _destinations);
    
    return Scaffold(
      body: _buildPageView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onDestinationSelected(index, _destinations),
        destinations: _destinations.map((dest) {
          return NavigationDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: dest.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
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

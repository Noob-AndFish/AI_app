// 路由配置
// 用 go_router 配置底部 5 Tab 导航

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/today/today_page.dart';
import '../features/memo/memo_page.dart';
import '../features/journal/journal_page.dart';
import '../features/stats/stats_page.dart';
import '../features/settings/settings_page.dart';

// 底部导航栏的 5 个 Tab 配置
final List<NavigationTab> navigationTabs = [
  NavigationTab(
    label: '今日',
    icon: Icons.today_outlined,
    selectedIcon: Icons.today,
  ),
  NavigationTab(
    label: '备忘录',
    icon: Icons.note_outlined,
    selectedIcon: Icons.note,
  ),
  NavigationTab(
    label: '日记',
    icon: Icons.book_outlined,
    selectedIcon: Icons.book,
  ),
  NavigationTab(
    label: '统计',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  NavigationTab(
    label: '设置',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

// Tab 的配置数据
class NavigationTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const NavigationTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// go_router 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShellPage(child: child),
      routes: [
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayPage(),
        ),
        GoRoute(
          path: '/memo',
          builder: (context, state) => const MemoPage(),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => const JournalPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

// 主壳页面：底部导航 + 内容区
class MainShellPage extends StatelessWidget {
  final Widget child;
  const MainShellPage({super.key, required this.child});

  // 路径到 Tab 索引的映射
  static const _pathToIndex = {
    '/today': 0,
    '/memo': 1,
    '/journal': 2,
    '/stats': 3,
    '/settings': 4,
  };

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // 取路径第一段（如 /today/memo 中的 today）
    final segment = '/${location.split('/').skip(1).firstOrNull ?? 'today'}';
    final currentIndex = _pathToIndex[segment] ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final paths = ['/today', '/memo', '/journal', '/stats', '/settings'];
          context.go(paths[index]);
        },
        destinations: navigationTabs
            .map((tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/socket_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    _TabItem(label: '채팅', icon: Icons.chat_bubble_outline_rounded, selectedIcon: Icons.chat_bubble_rounded, path: '/chats'),
    _TabItem(label: '친구', icon: Icons.people_outline_rounded, selectedIcon: Icons.people_rounded, path: '/friends'),
    _TabItem(label: '설정', icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, path: '/settings'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(socketServiceProvider).connect());
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return ResponsiveLayout(
      mobile: _MobileShell(tabs: _tabs, currentIndex: idx, child: widget.child),
      desktop: _WideShell(tabs: _tabs, currentIndex: idx, extended: true, child: widget.child),
      tablet: _WideShell(tabs: _tabs, currentIndex: idx, extended: false, child: widget.child),
    );
  }
}

// ── 모바일: BottomNavigationBar ──────────────────────────────────────────────
class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.child,
    required this.tabs,
    required this.currentIndex,
  });

  final Widget child;
  final List<_TabItem> tabs;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(tabs[i].path),
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.selectedIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

// ── 태블릿/데스크톱: NavigationRail ─────────────────────────────────────────
class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.child,
    required this.tabs,
    required this.currentIndex,
    required this.extended,
  });

  final Widget child;
  final List<_TabItem> tabs;
  final int currentIndex;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드 네비게이션
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => context.go(tabs[i].path),
            extended: extended,
            minWidth: 72,
            minExtendedWidth: 200,
            backgroundColor: AppColors.surfaceDefault,
            indicatorColor: AppColors.primarySurface,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: IconThemeData(color: AppColors.textSecondary.withValues(alpha: 0.7)),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            leading: extended
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '링톡',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.notifications_rounded, color: AppColors.primary, size: 28),
                  ),
            destinations: tabs
                .map((t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.selectedIcon),
                      label: Text(t.label),
                    ))
                .toList(),
          ),
          // 구분선
          const VerticalDivider(width: 1, thickness: 1),
          // 메인 컨텐츠
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

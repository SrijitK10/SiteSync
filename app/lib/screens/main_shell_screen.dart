import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/platform_utils.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure AppTheme._isDark is in sync with the current brightness
    AppTheme.syncWithContext(context);

    final location = GoRouterState.of(context).uri.path;
    final int currentIndex = location.startsWith('/dashboard') ? 1 : 0;

    final user = ref.watch(authProvider).currentUser;
    final canViewDashboard = user != null && user.role.canEdit;

    // Use theme-based colors so they're always correct for the current brightness
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.72);
    final bgColor = colorScheme.surface;

    // If the user doesn't have permission, they only see the projects screen
    // so we don't need a bottom navigation bar.
    if (!canViewDashboard) {
      return child;
    }

    if (isWindowsDesktop || MediaQuery.of(context).size.width > 800) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index == 0) context.go('/projects');
                if (index == 1) context.go('/dashboard');
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: bgColor,
              selectedIconTheme: IconThemeData(color: selectedColor),
              selectedLabelTextStyle: TextStyle(
                color: selectedColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedIconTheme: IconThemeData(color: unselectedColor),
              unselectedLabelTextStyle: TextStyle(
                color: unselectedColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.business, color: unselectedColor),
                  selectedIcon: Icon(
                    Icons.business,
                    color: selectedColor,
                  ),
                  label: const Text('Projects'),
                ),
                NavigationRailDestination(
                  icon: Icon(
                    Icons.assessment,
                    color: unselectedColor,
                  ),
                  selectedIcon: Icon(
                    Icons.assessment,
                    color: selectedColor,
                  ),
                  label: const Text('Dashboard'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0 && currentIndex != 0) context.go('/projects');
          if (index == 1 && currentIndex != 1) context.go('/dashboard');
        },
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        backgroundColor: bgColor,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.business, color: unselectedColor),
            activeIcon: Icon(Icons.business, color: selectedColor),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.assessment,
              color: unselectedColor,
            ),
            activeIcon: Icon(
              Icons.assessment,
              color: selectedColor,
            ),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

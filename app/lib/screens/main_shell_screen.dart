import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/platform_utils.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/drawn_app_icon.dart';
import '../widgets/quick_action_sheet.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure AppTheme._isDark is in sync with the current brightness
    AppTheme.syncWithContext(context);

    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 1;
    } else if (location.startsWith('/assistant')) {
      currentIndex = 2;
    }

    final user = ref.watch(authProvider).currentUser;

    // Use theme-based colors so they're always correct for the current brightness
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.72);
    final bgColor = colorScheme.surface;

    if (user == null) {
      return child;
    }

    if (isWindowsDesktop || MediaQuery.of(context).size.width > 800) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => QuickActionSheet.show(context),
          backgroundColor: selectedColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isWindowsDesktop 
              ? AppTheme.windowBackdropGradient(context)
              : null,
            color: !isWindowsDesktop ? bgColor : null,
          ),
          child: Row(
            children: [
              isWindowsDesktop ? AppTheme.buildGlassContainer(
                context,
                radius: 0,
                child: NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    if (index == 0) context.go('/projects');
                    if (index == 1) context.go('/dashboard');
                    if (index == 2) context.go('/assistant');
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.transparent,
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
                      icon: DrawnAppIcon(
                        kind: DrawnAppIconKind.projects,
                        color: unselectedColor,
                      ),
                      selectedIcon: DrawnAppIcon(
                        kind: DrawnAppIconKind.projects,
                        color: selectedColor,
                      ),
                      label: const Text('Projects'),
                    ),
                    NavigationRailDestination(
                      icon: DrawnAppIcon(
                        kind: DrawnAppIconKind.dashboard,
                        color: unselectedColor,
                      ),
                      selectedIcon: DrawnAppIcon(
                        kind: DrawnAppIconKind.dashboard,
                        color: selectedColor,
                      ),
                      label: const Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: DrawnAppIcon(
                        kind: DrawnAppIconKind.assistant,
                        color: unselectedColor,
                      ),
                      selectedIcon: DrawnAppIcon(
                        kind: DrawnAppIconKind.assistant,
                        color: selectedColor,
                      ),
                      label: const Text('Assistant'),
                    ),
                  ],
                ),
              ) : NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  if (index == 0) context.go('/projects');
                  if (index == 1) context.go('/dashboard');
                  if (index == 2) context.go('/assistant');
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
                    icon: DrawnAppIcon(
                      kind: DrawnAppIconKind.projects,
                      color: unselectedColor,
                    ),
                    selectedIcon: DrawnAppIcon(
                      kind: DrawnAppIconKind.projects,
                      color: selectedColor,
                    ),
                    label: const Text('Projects'),
                  ),
                  NavigationRailDestination(
                    icon: DrawnAppIcon(
                      kind: DrawnAppIconKind.dashboard,
                      color: unselectedColor,
                    ),
                    selectedIcon: DrawnAppIcon(
                      kind: DrawnAppIconKind.dashboard,
                      color: selectedColor,
                    ),
                    label: const Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: DrawnAppIcon(
                      kind: DrawnAppIconKind.assistant,
                      color: unselectedColor,
                    ),
                    selectedIcon: DrawnAppIcon(
                      kind: DrawnAppIconKind.assistant,
                      color: selectedColor,
                    ),
                    label: const Text('Assistant'),
                  ),
                ],
              ),
              if (!isWindowsDesktop) const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickActionSheet.show(context),
        backgroundColor: selectedColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0 && currentIndex != 0) context.go('/projects');
          if (index == 1 && currentIndex != 1) context.go('/dashboard');
          if (index == 2 && currentIndex != 2) context.go('/assistant');
        },
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        backgroundColor: bgColor,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: DrawnAppIcon(
              kind: DrawnAppIconKind.projects,
              color: unselectedColor,
            ),
            activeIcon: DrawnAppIcon(
              kind: DrawnAppIconKind.projects,
              color: selectedColor,
            ),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: DrawnAppIcon(
              kind: DrawnAppIconKind.dashboard,
              color: unselectedColor,
            ),
            activeIcon: DrawnAppIcon(
              kind: DrawnAppIconKind.dashboard,
              color: selectedColor,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: DrawnAppIcon(
              kind: DrawnAppIconKind.assistant,
              color: unselectedColor,
            ),
            activeIcon: DrawnAppIcon(
              kind: DrawnAppIconKind.assistant,
              color: selectedColor,
            ),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}

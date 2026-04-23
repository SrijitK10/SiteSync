import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../state/auth_provider.dart';
import '../state/projects_provider.dart';
import '../state/unread_tracker_provider.dart';
import '../services/platform_utils.dart';
import '../l10n/app_localizations.dart';
import 'attendance_screen.dart';
import 'calendar_screen.dart';
import 'tasks_tab.dart';
import 'gallery_tab.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;
  final String? projectLocation;

  const ProjectDashboardScreen({
    super.key,
    required this.projectId,
    this.projectName,
    this.projectLocation,
  });

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  int _currentIndex = 0;
  List<dynamic> _progressImages = [];

  @override
  void initState() {
    super.initState();
    _refreshProgressImages();
  }

  @override
  void didUpdateWidget(covariant ProjectDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _currentIndex = 0;
      _progressImages = [];
      _refreshProgressImages();
    }
  }

  Future<void> _refreshProgressImages() async {
    final currentUser = ref.read(authProvider).currentUser;
    final canViewProgress =
        currentUser != null && currentUser.role.value != 'viewer';
    if (!canViewProgress) return;

    try {
      final res = await apiClient.get('/projects/${widget.projectId}/images');
      if (!mounted) return;
      setState(() {
        _progressImages = List<dynamic>.from(res.data as List<dynamic>);
      });
    } catch (e) {
      debugPrint('Failed to load progress badge state: $e');
    }
  }

  void _handleProgressImagesViewed(List<dynamic> images) {
    if (!mounted) return;
    setState(() {
      _progressImages = List<dynamic>.from(images);
    });
  }

  void _onTabChanged(int index, {required bool isViewer, String? userId}) {
    setState(() => _currentIndex = index);

    final progressIndex = isViewer ? null : 3;
    if (progressIndex != null && index == progressIndex && userId != null) {
      ref
          .read(unreadTrackerProvider.notifier)
          .markProgressVisited(
            userId: userId,
            projectId: widget.projectId,
            images: _progressImages,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = isWindowsDesktop;
    final currentUser = ref.watch(authProvider).currentUser;
    ref.watch(unreadTrackerProvider);
    // Treat null user as viewer (safest default while state is loading)
    final isViewer = currentUser == null || currentUser.role.value == 'viewer';

    // Try to resolve project details if missing (e.g. deep linked from notification)
    final projects =
        ref.watch(projectsProvider).asData?.value ??
        const <Map<String, dynamic>>[];
    final currentProject = projects.firstWhere(
      (p) => p['id'] == widget.projectId,
      orElse: () => <String, dynamic>{},
    );

    final resolvedProjectName =
        widget.projectName ??
        (currentProject['name'] as String?) ??
        AppLocalizations.of(context)!.activeWorkspace;
    final resolvedProjectLocation =
        widget.projectLocation ?? (currentProject['location'] as String?);
    final progressTabIndex = isViewer ? null : 3;
    final progressUnreadCount = currentUser == null || isViewer
        ? 0
        : ref
              .read(unreadTrackerProvider.notifier)
              .unseenProgressItemCount(
                userId: currentUser.id,
                projectId: widget.projectId,
                images: _progressImages,
              );
    final effectiveProgressUnreadCount =
        progressTabIndex != null && _currentIndex == progressTabIndex
        ? 0
        : progressUnreadCount;

    // Isolated Stack mapping precise structural context directly below
    final List<Widget> pages = [
      TasksTab(projectId: widget.projectId),
      CalendarScreen(projectId: widget.projectId),
      if (!isViewer) AttendanceScreen(projectId: widget.projectId),
      if (!isViewer)
        GalleryTab(
          projectId: widget.projectId,
          projectName: resolvedProjectName,
          onImagesViewed: _handleProgressImagesViewed,
        ),
    ];

    // Clamp the tab index so it never exceeds the available pages.
    // This prevents a crash when the role changes mid-session and
    // the pages list shrinks (e.g. viewer → fewer tabs).
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: isWindows
            ? AppTheme.surface.withValues(alpha: 0.76)
            : AppTheme.surface,
        titleSpacing: isWindows ? 20 : null,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resolvedProjectName,
              style: AppTheme.body.copyWith(
                fontSize: isWindows ? 18 : 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (resolvedProjectLocation != null &&
                resolvedProjectLocation.isNotEmpty)
              Text(
                resolvedProjectLocation,
                style: AppTheme.label.copyWith(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pops out of the specific Project Workspace entirely back to Global Projects Landing
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/projects');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppLocalizations.of(context)!.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            if (isWindows) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Row(
                  children: [
                    Container(
                      decoration: AppTheme.desktopPaneDecoration(
                        context,
                        radius: 28,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: NavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (idx) => _onTabChanged(
                          idx,
                          isViewer: isViewer,
                          userId: currentUser?.id,
                        ),
                        labelType: NavigationRailLabelType.all,
                        useIndicator: true,
                        indicatorColor: AppTheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        minWidth: 104,
                        minExtendedWidth: 164,
                        backgroundColor: Colors.transparent,
                        selectedIconTheme: IconThemeData(
                          color: AppTheme.primary,
                        ),
                        selectedLabelTextStyle: AppTheme.label.copyWith(
                          color: AppTheme.primary,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: AppTheme.textSecondary,
                        ),
                        unselectedLabelTextStyle: AppTheme.label.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Icons.assignment),
                            label: Text(
                              AppLocalizations.of(context)!.tasksTitle,
                            ),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              AppLocalizations.of(context)!.calendarTitle,
                            ),
                          ),
                          if (!isViewer)
                            NavigationRailDestination(
                              icon: const Icon(Icons.co_present),
                              label: Text(
                                AppLocalizations.of(context)!.attendanceTitle,
                              ),
                            ),
                          if (!isViewer)
                            NavigationRailDestination(
                              icon: _BottomNavUnreadIcon(
                                icon: Icons.photo_library,
                                unreadCount: effectiveProgressUnreadCount,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.progressTitle,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        decoration: AppTheme.desktopPaneDecoration(
                          context,
                          radius: 28,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pages[_currentIndex],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => _onTabChanged(
                    idx,
                    isViewer: isViewer,
                    userId: currentUser?.id,
                  ),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppTheme.surface,
                  selectedIconTheme: IconThemeData(color: AppTheme.primary),
                  selectedLabelTextStyle: AppTheme.label.copyWith(
                    color: AppTheme.primary,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: AppTheme.textSecondary,
                  ),
                  unselectedLabelTextStyle: AppTheme.label.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.assignment),
                      label: Text(AppLocalizations.of(context)!.tasksTitle),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(AppLocalizations.of(context)!.calendarTitle),
                    ),
                    if (!isViewer)
                      NavigationRailDestination(
                        icon: const Icon(Icons.co_present),
                        label: Text(
                          AppLocalizations.of(context)!.attendanceTitle,
                        ),
                      ),
                    if (!isViewer)
                      NavigationRailDestination(
                        icon: _BottomNavUnreadIcon(
                          icon: Icons.photo_library,
                          unreadCount: effectiveProgressUnreadCount,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.progressTitle,
                        ),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_currentIndex]),
              ],
            );
          }
          return pages[_currentIndex];
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => _onTabChanged(
                idx,
                isViewer: isViewer,
                userId: currentUser?.id,
              ),
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              backgroundColor: AppTheme.surface,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.assignment),
                  label: AppLocalizations.of(context)!.tasksTitle,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_month),
                  label: AppLocalizations.of(context)!.calendarTitle,
                ),
                if (!isViewer)
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.co_present),
                    label: AppLocalizations.of(context)!.attendanceTitle,
                  ),
                if (!isViewer)
                  BottomNavigationBarItem(
                    icon: _BottomNavUnreadIcon(
                      icon: Icons.photo_library,
                      unreadCount: effectiveProgressUnreadCount,
                    ),
                    label: AppLocalizations.of(context)!.progressTitle,
                  ),
              ],
            )
          : null,
    );
  }
}

class _BottomNavUnreadIcon extends StatelessWidget {
  final IconData icon;
  final int unreadCount;

  const _BottomNavUnreadIcon({required this.icon, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final visibleCount = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (unreadCount > 0)
          Positioned(
            top: -6,
            right: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                visibleCount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

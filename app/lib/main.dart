import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/project_dashboard_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/projects_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/projects',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/projects';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/users',
        builder: (context, state) => const UserManagementScreen(),
        redirect: (context, state) {
          final user = ref.read(authProvider).currentUser;
          if (user == null || !user.role.isAdmin) {
            return '/projects';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProjectDashboardScreen(
            projectId: projectId,
            projectName: extra['name'] as String?,
            projectLocation: extra['location'] as String?,
          );
        },
      ),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: SiteSyncApp(),
    ),
  );
}

class SiteSyncApp extends ConsumerWidget {
  const SiteSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SiteSync',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/project_dashboard_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/projects_screen.dart';

// Provide router dependency on AuthState so redirects can happen reactively
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/projects',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/forgot-password';
      
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/projects';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/users',
        builder: (context, state) => const UserManagementScreen(),
        redirect: (context, state) {
          final user = ref.read(authProvider).currentUser;
          // Only admins and super admins can access user management
          if (user == null || !user.role.isAdmin) {
            return '/projects'; // Redirect back
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
          return ProjectDashboardScreen(projectId: projectId);
        },
      ),

    ],
  );
});

void main() {
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

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';

import 'services/keep_alive_service.dart';
import 'services/notification_service.dart';
import 'services/platform_utils.dart';
import 'theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/project_dashboard_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/share_to_task_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authProvider);

    // While restoring session, don't redirect anywhere.
    if (authState.isLoading) return null;

    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password';

    if (!authState.isAuthenticated) {
      return isAuthRoute ? null : '/login';
    }

    if (isAuthRoute) {
      return '/projects';
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _RupayanAppState.navigatorKey,
    initialLocation: '/projects',
    refreshListenable: refreshNotifier,
    redirect: refreshNotifier.redirect,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
          if (user == null) return '/login';
          if (!user.role.isAdmin) return '/projects';
          return null;
        },
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
  if (!isWindowsDesktop) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  KeepAliveService.start();
  runApp(ProviderScope(child: RupayanApp()));
}

class RupayanApp extends ConsumerStatefulWidget {
  const RupayanApp({super.key});

  @override
  ConsumerState<RupayanApp> createState() => _RupayanAppState();
}

class _RupayanAppState extends ConsumerState<RupayanApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _routeSubscription;
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  /// Global navigator key so we can push the share-to-task picker from any context.
  static final navigatorKey = GlobalKey<NavigatorState>();

  Widget _buildAppShell({
    required BuildContext context,
    required Widget? child,
    required AppSettingsState settings,
  }) {
    AppTheme.syncWithContext(context);
    final mediaQuery = MediaQuery.of(context);
    final brightness = Theme.of(context).brightness;

    // Style the system navigation bar to blend with the app
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return KeyedSubtree(
      key: ValueKey(
        '${settings.themeMode.name}-${settings.textScalePreset.name}-${brightness.name}-${settings.locale.languageCode}',
      ),
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(settings.textScalePreset.scale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeSubscription = NotificationService().onRoute.listen((route) {
      ref.read(routerProvider).push(route);
    });
    if (!isWindowsDesktop) {
      _initShareListener();
    }
  }

  void _initShareListener() {
    // Handle files shared while app is open
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) _handleSharedFiles(files);
      },
      onError: (e) => debugPrint('Share listener error: $e'),
    );

    // Handle files shared when app was closed
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty) _handleSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> sharedFiles) {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    final files = sharedFiles
        .where((f) => f.path.isNotEmpty)
        .map((f) => File(f.path))
        .where((f) => f.existsSync())
        .toList();

    if (files.isEmpty) return;

    // Push the share-to-task picker
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => ShareToTaskScreen(sharedFiles: files),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeSubscription?.cancel();
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On every resume, re-fetch the current user so the local role cache
    // tracks whatever the backend says — even if an admin was promoted or
    // demoted while the app was in the background.
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        ref.read(authProvider.notifier).refreshCurrentUser();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);

    if (authState.isLoading) {
      return MaterialApp(
        key: ValueKey('app-${settings.locale.languageCode}'),
        title: 'Rupayan',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        locale: settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            _buildAppShell(context: context, child: child, settings: settings),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      key: ValueKey('app-${settings.locale.languageCode}'),
      title: 'Rupayan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          _buildAppShell(context: context, child: child, settings: settings),
    );
  }
}

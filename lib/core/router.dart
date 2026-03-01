import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/cycle/cycle_setup_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // glance-action 등 위젯 딥링크는 GoRouter가 처리할 수 없으므로 홈으로 리다이렉트
    final scheme = state.uri.scheme;
    if (scheme.isNotEmpty && scheme != 'https' && scheme != 'http') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/cycle-setup',
      builder: (context, state) => const CycleSetupScreen(),
    ),
  ],
);

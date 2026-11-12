import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/practice/mock_setup_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/practice/quiz_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/tutor/tutor_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final refresh = AuthRefresh(supabase.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = supabase.auth.currentSession != null;
      final atAuth = state.matchedLocation == '/auth';
      if (!signedIn && !atAuth) return '/auth';
      if (signedIn && atAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (c, s) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: '/tutor', pageBuilder: (c, s) => const NoTransitionPage(child: TutorScreen())),
          GoRoute(path: '/practice', pageBuilder: (c, s) => const NoTransitionPage(child: PracticeScreen())),
          GoRoute(path: '/progress', pageBuilder: (c, s) => const NoTransitionPage(child: ProgressScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      GoRoute(path: '/mock', builder: (context, state) => const MockSetupScreen()),
      GoRoute(
        path: '/quiz',
        builder: (context, state) {
          final session = state.extra;
          if (session is! QuizSession) return const _MissingSession();
          return QuizScreen(session: session);
        },
      ),
      GoRoute(path: '/premium', builder: (context, state) => const PremiumScreen()),
    ],
  );
});

class _MissingSession extends StatelessWidget {
  const _MissingSession();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/practice'), child: const Text('Back to practice')),
        ),
      );
}

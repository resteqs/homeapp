import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:homeapp/pages/home_page.dart';
import 'package:homeapp/pages/auth_page.dart';

/// Rebuild trigger for GoRouter based on stream events.
///
/// Used for auth state stream so redirects run immediately after sign in/out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

@NowaGenerated()
final GoRouter appRouter = GoRouter(
  initialLocation: '/home-page',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isGoingToAuth = state.uri.path == '/auth';

    if (session == null && !isGoingToAuth) {
      return '/auth';
    }
    if (session != null && isGoingToAuth) {
      return '/home-page';
    }
    return null;
  },
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/home-page',
      builder: (context, state) => const HomePage(),
    ),
  ],
);

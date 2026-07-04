import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/followers_screen.dart';
import '../../features/profile/following_screen.dart';
import '../../features/error/error_screen.dart';
import '../../features/error/backend_down_screen.dart';
import '../../features/messages/chat_detail_screen.dart';

// Slide-up from bottom transition (used for auth pages)
CustomTransitionPage<void> _slideUpTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: const Interval(0.0, 0.7)));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(tween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String notFound = '/404';
  static const String backendDown = '/backend-down';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,
    errorBuilder: (context, state) => const ErrorScreen(),
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: signup,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: backendDown,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const BackendDownScreen(),
        ),
      ),
      // Own profile (no ID param — backwards compatible)
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      // Profile by user ID
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return ProfileScreen(userId: userId);
        },
        routes: [
          GoRoute(
            path: 'followers',
            builder: (context, state) {
              final userId = state.pathParameters['id']!;
              return FollowersScreen(userId: userId);
            },
          ),
          GoRoute(
            path: 'following',
            builder: (context, state) {
              final userId = state.pathParameters['id']!;
              return FollowingScreen(userId: userId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (context, state) {
          final threadId = state.pathParameters['threadId']!;
          return ChatDetailScreen(threadId: threadId);
        },
      ),
      GoRoute(
        path: notFound,
        builder: (context, state) => const ErrorScreen(),
      ),
    ],
  );
}

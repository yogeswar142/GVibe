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

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String notFound = '/404';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    errorBuilder: (context, state) => const ErrorScreen(),
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
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
        path: notFound,
        builder: (context, state) => const ErrorScreen(),
      ),
    ],
  );
}

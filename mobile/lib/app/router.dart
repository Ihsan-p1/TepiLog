import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/app/main_shell.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/features/auth/presentation/screens/login_screen.dart';
import 'package:tepilog/features/auth/presentation/screens/register_screen.dart';
import 'package:tepilog/features/map/presentation/screens/home_screen.dart';
import 'package:tepilog/features/map/presentation/screens/location_detail_screen.dart';
import 'package:tepilog/features/post/presentation/screens/post_detail_screen.dart';
import 'package:tepilog/features/post/presentation/screens/upload_screen.dart';
import 'package:tepilog/features/trending/presentation/screens/trending_screen.dart';
import 'package:tepilog/features/profile/presentation/screens/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ponytail: screens not yet redesigned keep their dark look in light mode too;
// each step of the redesign drops its screen from this wrapper.
Widget _legacy(Widget screen) => Theme(data: AppTheme.dark, child: screen);

// The bottom nav has four items but the shell has three branches: upload
// (nav 2) is pushed full screen, so profile is nav 3 and branch 2.
int navIndexForBranch(int branch) => branch >= 2 ? branch + 1 : branch;
int branchForNavIndex(int nav) => nav > 2 ? nav - 1 : nav;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => _legacy(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => _legacy(const RegisterScreen()),
      ),

      // Shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navIndexForBranch(navigationShell.currentIndex),
            onTabChanged: (index) {
              // Index 2 = Upload, push fullscreen instead of switching tab
              if (index == 2) {
                context.pushNamed('upload');
                return;
              }
              final branch = branchForNavIndex(index);
              navigationShell.goBranch(
                branch,
                initialLocation: branch == navigationShell.currentIndex,
              );
            },
            child: navigationShell,
          );
        },
        branches: [
          // Tab 0: Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1: Trending
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trending',
                name: 'trending',
                builder: (context, state) => _legacy(const TrendingScreen()),
              ),
            ],
          ),
          // Tab 2: Profile (index 3 in bottom nav, but branch index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => _legacy(const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // Fullscreen routes (no bottom nav)
      GoRoute(
        path: '/upload',
        name: 'upload',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => _legacy(const UploadScreen()),
      ),
      GoRoute(
        path: '/location/:id',
        name: 'location-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LocationDetailScreen(locationId: id);
        },
      ),
      GoRoute(
        path: '/post/:id',
        name: 'post-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _legacy(PostDetailScreen(postId: id));
        },
      ),
    ],
  );
});

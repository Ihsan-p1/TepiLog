import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/app/main_shell.dart';
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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navigationShell.currentIndex,
            onTabChanged: (index) {
              // Index 2 = Upload, push fullscreen instead of switching tab
              if (index == 2) {
                context.pushNamed('upload');
                return;
              }
              navigationShell.goBranch(
                index > 2 ? index - 1 : index,
                initialLocation: index == navigationShell.currentIndex,
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
                builder: (context, state) => const TrendingScreen(),
              ),
            ],
          ),
          // Tab 2: Profile (index 3 in bottom nav, but branch index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
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
        builder: (context, state) => const UploadScreen(),
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
          return PostDetailScreen(postId: id);
        },
      ),
    ],
  );
});

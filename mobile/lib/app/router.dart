import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/features/auth/presentation/screens/login_screen.dart';
import 'package:tepilog/features/auth/presentation/screens/register_screen.dart';
import 'package:tepilog/features/map/presentation/screens/home_screen.dart';

import 'package:tepilog/features/map/presentation/screens/location_detail_screen.dart';
import 'package:tepilog/features/post/presentation/screens/upload_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
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
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/location/:id',
        name: 'location-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LocationDetailScreen(locationId: id);
        },
      ),
      GoRoute(
        path: '/upload',
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
      ),
    ],
  );
});

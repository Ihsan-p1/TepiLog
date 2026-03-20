import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/auth/data/auth_repository.dart';
import 'package:tepilog/features/auth/domain/user.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

// Auth state
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _authRepo => AuthRepository(ref.read(dioProvider));

  Future<void> checkAuth() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    if (tokenStorage.hasToken) {
      final userData = tokenStorage.userData;
      if (userData != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: User.fromJson(userData),
        );
        return;
      }
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final result = await _authRepo.register(
        email: email,
        password: password,
        username: username,
      );
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await tokenStorage.saveUserData(result.user.toJson());
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['error'] as String? ?? 'Registrasi gagal';
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    } catch (e) {
      debugPrint('Register error: $e');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Terjadi kesalahan, coba lagi',
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final result = await _authRepo.login(
        email: email,
        password: password,
      );
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await tokenStorage.saveUserData(result.user.toJson());
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['error'] as String? ?? 'Login gagal';
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Terjadi kesalahan, coba lagi',
      );
    }
  }

  Future<void> logout() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

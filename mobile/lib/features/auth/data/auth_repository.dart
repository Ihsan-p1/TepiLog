import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tepilog/shared/constants/api_constants.dart';
import 'package:tepilog/features/auth/domain/user.dart';
import 'package:tepilog/features/auth/domain/auth_response.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<({User user, AuthResponse tokens})> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'username': username,
      },
    );

    final data = response.data as Map<String, dynamic>;
    debugPrint('Register response: $data');

    // Backend returns: { user: {...}, accessToken, refreshToken }
    final userData = data['user'] as Map<String, dynamic>;
    return (
      user: User.fromJson(userData),
      tokens: AuthResponse.fromJson(data),
    );
  }

  Future<({User user, AuthResponse tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    debugPrint('Login response: $data');

    // Backend returns: { user: {...}, accessToken, refreshToken }
    final userData = data['user'] as Map<String, dynamic>;
    return (
      user: User.fromJson(userData),
      tokens: AuthResponse.fromJson(data),
    );
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

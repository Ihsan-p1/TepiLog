import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/shared/constants/api_constants.dart';
import 'package:tepilog/features/auth/data/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final tokenStorage = ref.read(tokenStorageProvider);

  // Request interceptor — attach JWT
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStorage.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshTokenValue = tokenStorage.refreshToken;
          if (refreshTokenValue != null) {
            try {
              // Try refresh with a separate Dio instance
              final refreshDio = Dio(
                BaseOptions(baseUrl: ApiConstants.baseUrl),
              );
              final response = await refreshDio.post(
                ApiConstants.refresh,
                data: {'refreshToken': refreshTokenValue},
              );

              final newAccessToken = response.data['accessToken'] as String;
              final newRefreshToken = response.data['refreshToken'] as String;
              await tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final retryResponse = await refreshDio.fetch(
                error.requestOptions,
              );
              return handler.resolve(retryResponse);
            } catch (_) {
              // Refresh failed — clear tokens (auth provider will handle redirect)
              await tokenStorage.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

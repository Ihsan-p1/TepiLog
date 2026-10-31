import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tepilog/features/auth/data/token_storage.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/features/demo/data/demo_interceptor.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

import 'demo_test_helpers.dart';

void main() {
  late TestStoreEnv env;
  late DemoStore store;
  late TokenStorage tokens;

  setUp(() async {
    env = await TestStoreEnv.create();
    store = await env.open();
    tokens = TokenStorage();
    await tokens.init();
  });

  tearDown(() async => Hive.close());

  ProviderContainer containerFor(DemoStore s) => ProviderContainer.test(overrides: [
        demoStoreProvider.overrideWithValue(s),
        tokenStorageProvider.overrideWithValue(tokens),
      ]);

  test('enterDemo signs in as the demo visitor', () async {
    final c = containerFor(store);
    await c.read(authProvider.notifier).enterDemo();

    expect(c.read(authProvider).status, AuthStatus.authenticated);
    expect(c.read(authProvider).user?.username, 'demo');
    expect(c.read(demoModeProvider), isTrue);
  });

  test('dio in demo mode carries only the demo interceptor', () async {
    final c = containerFor(store);
    await c.read(authProvider.notifier).enterDemo();

    final interceptors = c.read(dioProvider).interceptors;
    expect(interceptors.whereType<DemoInterceptor>(), hasLength(1));
    expect(interceptors.whereType<InterceptorsWrapper>(), isEmpty);
  });

  test('checkAuth restores demo after restart', () async {
    await containerFor(store).read(authProvider.notifier).enterDemo();

    final restarted = containerFor(await env.open());
    await restarted.read(authProvider.notifier).checkAuth();
    expect(restarted.read(authProvider).status, AuthStatus.authenticated);
    expect(restarted.read(authProvider).user?.username, 'demo');
  });

  test('logout in demo resets the data and leaves demo', () async {
    final c = containerFor(store);
    final auth = c.read(authProvider.notifier);
    await auth.enterDemo();
    await store.createPost(
      bytes: [1],
      filename: 'a.jpg',
      latitude: -7.1867,
      longitude: 109.9228,
      takenAt: DateTime.utc(2025, 5, 28),
    );

    await auth.logout();
    expect(c.read(authProvider).status, AuthStatus.unauthenticated);
    expect(c.read(demoModeProvider), isFalse);

    await auth.enterDemo();
    expect(store.postsByLocation('seed-loc-prau').data, hasLength(3));
    expect(store.myPosts(), isEmpty);
  });

  test('map starts at Prau in demo', () async {
    final c = containerFor(store);
    await c.read(authProvider.notifier).enterDemo();

    expect(c.read(mapProvider).cameraPosition, kDemoCenter);
  });

  test('entering demo ends a real session, so logout leaves no token behind',
      () async {
    await tokens.saveTokens(accessToken: 'real-a', refreshToken: 'real-r');
    final c = containerFor(store);
    final auth = c.read(authProvider.notifier);

    await auth.enterDemo();
    await auth.logout();

    expect(tokens.hasToken, isFalse);
  });

  /// A container whose server answers login only after [reply] completes,
  /// with success when [ok] is true and a timeout otherwise.
  ProviderContainer slowLogin(Completer<void> reply, {required bool ok}) {
    final slowServer = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
        await reply.future;
        if (!ok) {
          return h.reject(DioException.receiveTimeout(
              timeout: const Duration(seconds: 10), requestOptions: o));
        }
        h.resolve(Response(requestOptions: o, statusCode: 200, data: {
          'user': {
            'id': 'real-user',
            'email': 'real@x.id',
            'username': 'real',
            'avatar_url': null,
            'created_at': '2025-01-01T00:00:00.000Z',
          },
          'accessToken': 'real-a',
          'refreshToken': 'real-r',
        }));
      }));
    return ProviderContainer.test(overrides: [
      demoStoreProvider.overrideWithValue(store),
      tokenStorageProvider.overrideWithValue(tokens),
      dioProvider.overrideWithValue(slowServer),
    ]);
  }

  for (final ok in [true, false]) {
    test('a login ${ok ? 'reply' : 'timeout'} after entering demo is ignored',
        () async {
      final reply = Completer<void>();
      final c = slowLogin(reply, ok: ok);
      final auth = c.read(authProvider.notifier);

      final login = auth.login(email: 'real@x.id', password: 'secret');
      await auth.enterDemo();
      reply.complete();
      await login;

      expect(c.read(authProvider).status, AuthStatus.authenticated);
      expect(c.read(authProvider).user?.username, 'demo');
      expect(tokens.hasToken, isFalse);
    });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/auth/data/token_storage.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:tepilog/shared/providers/server_status_provider.dart';
import 'package:tepilog/shared/widgets/server_wake_gate.dart';

/// Demo mode without the Hive store: enter() only flips the flag.
class _FakeDemoMode extends DemoModeNotifier {
  @override
  bool build() => false;

  @override
  Future<void> enter() async => state = true;
}

/// No Hive box in widget tests; entering demo only needs clear() to succeed.
class _NoTokens extends TokenStorage {
  @override
  Future<void> clear() async {}
}

const _wakeText ='Server sedang bangun, biasanya sekitar 1 menit';
const _appText = 'app';
// Covers both a timeout and an instant refusal, so it names no duration.
const _failText = 'Server tidak bisa dihubungi.';

void main() {
  late Completer<void> reply;

  Future<void> pumpGate(WidgetTester tester,
      {Future<void> Function()? ping}) async {
    // Created here, inside the fake-time zone; a Completer made in setUp
    // delivers its reply on the real event loop, after pump has returned.
    reply = Completer<void>();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        demoModeProvider.overrideWith(_FakeDemoMode.new),
        tokenStorageProvider.overrideWithValue(_NoTokens()),
        healthPingProvider.overrideWithValue(ping ?? () => reply.future),
      ],
      child: const MaterialApp(
        home: ServerWakeGate(child: Text(_appText)),
      ),
    ));
  }

  testWidgets('reply within 3 s never shows the wake screen', (tester) async {
    await pumpGate(tester);
    await tester.pump(const Duration(seconds: 2));
    reply.complete();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text(_wakeText), findsNothing);
    expect(find.text(_appText), findsOneWidget);
  });

  testWidgets('slow reply shows the wake screen, then the app', (tester) async {
    await pumpGate(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(_wakeText), findsOneWidget);

    reply.complete();
    await tester.pump();
    expect(find.text(_wakeText), findsNothing);
    expect(find.text(_appText), findsOneWidget);
  });

  testWidgets('refused connection shows the failure state', (tester) async {
    await pumpGate(tester, ping: () async => throw Exception('refused'));
    await tester.pump();

    expect(find.text(_failText), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    // Offline the login screen is unreachable, so demo is offered here too.
    expect(find.text('Coba demo'), findsOneWidget);
    expect(find.text(_wakeText), findsNothing);
  });

  testWidgets('Coba lagi keeps the gate up instead of flashing the app',
      (tester) async {
    var calls = 0;
    await pumpGate(tester, ping: () {
      calls++;
      return calls == 1 ? Future.error(Exception('refused')) : reply.future;
    });
    await tester.pump();

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(find.text(_appText), findsNothing);
    expect(find.text(_wakeText), findsOneWidget);

    reply.complete();
    await tester.pump();
    expect(find.text(_appText), findsOneWidget);
  });

  testWidgets('no reply in 90 s shows the failure state', (tester) async {
    await pumpGate(tester);
    await tester.pump(const Duration(seconds: 90));

    expect(find.text(_failText), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('Coba demo sambil menunggu enters demo', (tester) async {
    await pumpGate(tester);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Coba demo sambil menunggu'));
    await tester.pump();

    final container =
        ProviderScope.containerOf(tester.element(find.text(_appText)));
    expect(container.read(demoModeProvider), isTrue);
    expect(find.text(_wakeText), findsNothing);
    // A late reply after entering demo must not bring the gate back.
    await tester.pump(const Duration(seconds: 90));
    expect(find.text(_appText), findsOneWidget);
  });
}

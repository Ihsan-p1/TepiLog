import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_interceptor.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/features/post/presentation/providers/upload_provider.dart';
import 'package:tepilog/features/post/presentation/screens/tag_on_map_screen.dart';
import 'package:tepilog/features/post/presentation/screens/upload_screen.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

import '../demo/demo_test_helpers.dart';

/// Upload state with a photo already picked, so the location step is reachable.
class _Picked extends UploadNotifier {
  _Picked(this.photo);
  final File photo;

  @override
  UploadState build() => UploadState(selectedImage: photo);
}

class _FixedDemoMode extends DemoModeNotifier {
  _FixedDemoMode(this.value);
  final bool value;

  @override
  bool build() => value;
}

void main() {
  late Dio dio;
  late File photo;

  setUp(() async {
    final store = await (await TestStoreEnv.create()).open();
    dio = Dio()..interceptors.add(DemoInterceptor(store));
    photo = File('${Directory.systemTemp.createTempSync('tepilog_up_').path}/a.jpg')
      ..writeAsBytesSync([0]);
  });

  tearDown(() async => Hive.close());

  /// Opens the upload screen on its location step.
  Future<void> pumpLocationStep(WidgetTester tester, {bool demo = false}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        uploadProvider.overrideWith(() => _Picked(photo)),
        dioProvider.overrideWithValue(dio),
        demoModeProvider.overrideWith(() => _FixedDemoMode(demo)),
      ],
      child: const MaterialApp(home: UploadScreen()),
    ));
    await tester.tap(find.text('Lanjut'));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('tag map opens at Prau in demo mode', (tester) async {
    await pumpLocationStep(tester, demo: true);
    await tester.tap(find.text('Tag di Peta'));
    await tester.pump(const Duration(seconds: 1)); // page transition
    await tester.pump();

    final map = tester.widget<TagOnMapScreen>(find.byType(TagOnMapScreen));
    expect((map.initialLat, map.initialLng),
        (kDemoCenter.latitude, kDemoCenter.longitude));
  });

  testWidgets('location name suggests places while the keyboard is open',
      (tester) async {
    await pumpLocationStep(tester);

    await tester.showKeyboard(find.byType(TextField));
    // The soft keyboard changes the view insets, which rebuilds the screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump(const Duration(seconds: 1));

    tester.testTextInput.enterText('Prau');
    // Dio runs the search on timers, so let fake time pass.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gunung Prau'), findsOneWidget);
    await tester.tap(find.text('Gunung Prau'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Lokasi: -7.1867, 109.9228'), findsOneWidget);
  });
}

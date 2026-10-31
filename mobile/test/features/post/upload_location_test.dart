import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_interceptor.dart';
import 'package:tepilog/features/post/presentation/providers/upload_provider.dart';
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

  testWidgets('location name suggests places while the keyboard is open',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        uploadProvider.overrideWith(() => _Picked(photo)),
        dioProvider.overrideWithValue(dio),
      ],
      child: const MaterialApp(home: UploadScreen()),
    ));
    await tester.tap(find.text('Lanjut'));
    await tester.pump(const Duration(seconds: 1));

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

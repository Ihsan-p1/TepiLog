import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

/// A 32×32 PNG filled with one colour.
Future<MemoryImage> _solid(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 32, 32), Paint()..color = color);
  final image = await recorder.endRecording().toImage(32, 32);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(png!.buffer.asUint8List());
}

void main() {
  test('url prefixes pick the matching image provider', () {
    expect(tepiImageProvider('asset:assets/demo/prau/prau-01.jpg'), isA<AssetImage>());
    expect(tepiImageProvider('file:/tmp/x.jpg'), isA<FileImage>());
    expect(tepiImageProvider('https://res.cloudinary.com/a.jpg'), isA<NetworkImage>());
  });

  testWidgets('an orange photo lends an orange accent in both themes', (tester) async {
    await tester.runAsync(() async {
      final photo = await _solid(const Color(0xFFE07A2E));
      for (final brightness in Brightness.values) {
        final scheme = await schemeFromPhoto(photo, brightness);
        final hue = HSVColor.fromColor(scheme!.primary).hue;
        expect(hue, inInclusiveRange(10, 40), reason: '$brightness');
        expect(scheme.brightness, brightness);
      }
    });
  });

  testWidgets('a photo that fails to load gives no scheme', (tester) async {
    await tester.runAsync(() async {
      final scheme = await schemeFromPhoto(
        const AssetImage('assets/demo/does-not-exist.jpg'),
        Brightness.light,
      );
      expect(scheme, isNull);
    });
  });
}

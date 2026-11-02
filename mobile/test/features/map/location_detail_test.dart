import 'dart:ui' show Tristate;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/map/presentation/screens/location_detail_screen.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';

Map<String, dynamic> _post(String id, String takenAt) => {
      'id': id,
      'media_url': 'asset:assets/demo/prau/prau-01.jpg',
      'media_type': 'photo',
      'caption': null,
      'taken_at': takenAt,
      'uploaded_at': takenAt,
      'user_id': 'u',
      'location_id': 'prau',
      'user': {'id': 'u', 'username': 'tomorrow', 'avatar_url': null},
      '_count': {'comments': 0},
    };

/// Answers the three calls the screen makes, or fails them all.
class _Api extends Interceptor {
  _Api(this.posts, {this.fail = false});

  final List<Map<String, dynamic>> posts;
  bool fail;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler handler) {
    if (fail) {
      handler.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError));
      return;
    }
    final data = switch (o.path) {
      '/locations/prau' => {
          'id': 'prau',
          'name': 'Gunung Prau',
          'latitude': -7.1867,
          'longitude': 109.9228,
          'post_count': posts.length,
        },
      '/posts' => {'data': posts, 'nextCursor': null, 'hasMore': false},
      _ => {'saved': false},
    };
    handler.resolve(Response(requestOptions: o, data: data, statusCode: 200));
  }
}

void main() {
  Future<_Api> pumpDetail(WidgetTester tester, List<Map<String, dynamic>> posts,
      {bool fail = false}) async {
    // A phone-sized screen (Pixel-class, 411 x 914 dp).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final api = _Api(posts, fail: fail);
    final dio = Dio()..interceptors.add(api);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        // Colour extraction decodes on the real event loop; tests skip it.
        photoSchemeProvider.overrideWith((ref, key) async => null),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LocationDetailScreen(locationId: 'prau'),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    return api;
  }

  testWidgets('several years get a year bar and one chapter each', (tester) async {
    await pumpDetail(tester, [
      _post('a', '2025-05-28T01:34:00.000Z'),
      _post('b', '2019-08-17T22:00:00.000Z'),
    ]);

    expect(find.text('Gunung Prau'), findsOneWidget);
    expect(find.text('2 foto · 2019–2025'), findsOneWidget);
    expect(find.bySemanticsLabel('Bab 2025'), findsOneWidget);
    expect(find.bySemanticsLabel('Bab 2019'), findsOneWidget);
  });

  testWidgets('a year chip scrolls to its chapter and lights up', (tester) async {
    await pumpDetail(tester, [
      for (final y in [2025, 2023, 2021, 2019])
        for (var i = 0; i < 4; i++) _post('$y-$i', '$y-05-1${i}T01:00:00.000Z'),
    ]);
    final chip2019 = find.bySemanticsLabel('Tahun 2019');
    expect(tester.getSemantics(chip2019).flagsCollection.isSelected, Tristate.isFalse);

    await tester.tap(chip2019);
    await tester.pumpAndSettle();

    expect(tester.getSemantics(chip2019).flagsCollection.isSelected, Tristate.isTrue);
    // On screen (914 dp tall), not left below the fold.
    expect(tester.getBottomLeft(find.bySemanticsLabel('Bab 2019')).dy, lessThan(914));
  });

  testWidgets('one year goes straight to a grid without a year bar', (tester) async {
    await pumpDetail(tester, [
      _post('a', '2025-05-28T01:34:00.000Z'),
      _post('b', '2025-05-28T01:40:00.000Z'),
    ]);

    expect(find.bySemanticsLabel(RegExp('^Bab ')), findsNothing);
    expect(find.byType(SliverGrid), findsOneWidget);
  });

  testWidgets('a failed load says so and can retry', (tester) async {
    final api = await pumpDetail(tester, [_post('a', '2025-05-28T01:34:00.000Z')], fail: true);

    expect(find.text('Tempat ini gagal dimuat.'), findsOneWidget);
    expect(find.text('Belum ada foto'), findsNothing);

    api.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Gunung Prau'), findsOneWidget);
  });
}

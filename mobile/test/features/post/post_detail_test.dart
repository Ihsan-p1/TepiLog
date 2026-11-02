import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/post/presentation/screens/post_detail_screen.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';

const _place = {'id': 'prau', 'name': 'Gunung Prau', 'latitude': -7.18, 'longitude': 109.92};

Map<String, dynamic> _post(String id, String takenAt, {String? caption}) => {
      'id': id,
      'media_url': 'asset:assets/demo/prau/prau-01.jpg',
      'media_type': 'photo',
      'caption': caption,
      'taken_at': takenAt,
      'uploaded_at': '2025-06-01T00:00:00.000Z',
      'user_id': 'u',
      'location_id': 'prau',
      'user': {'id': 'u', 'username': 'tomorrow', 'avatar_url': null},
      '_count': {'comments': 0},
    };

Map<String, dynamic> _comment(String body, {String user = 'raka', String at = '2025-06-02T00:00:00.000Z'}) => {
      'id': body,
      'body': body,
      'created_at': at,
      'user': {'id': user, 'username': user, 'avatar_url': null},
    };

/// Three photos of one place, taken 2019, 2023 and 2025. Comments only on
/// the 2023 photo, newest first like the API.
class _Api extends Interceptor {
  bool fail = false;
  final posts = [
    _post('p2025', '2025-05-28T01:34:00.000Z', caption: 'Sindoro dari puncak'),
    _post('p2019', '2019-08-17T22:00:00.000Z'),
    _post('p2023', '2023-05-11T01:00:00.000Z', caption: 'Kabut pagi'),
  ];
  final comments = <String, List<Map<String, dynamic>>>{
    'p2023': [
      _comment('Iya, sekitar 3 jam naik.', user: 'tomorrow', at: '2025-06-03T00:00:00.000Z'),
      _comment('Ini jalur Patak Banteng?'),
    ],
  };

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler handler) {
    if (fail) {
      handler.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError));
      return;
    }
    final seg = o.path.split('/').where((s) => s.isNotEmpty).toList();
    final Object data = switch ((o.method, seg)) {
      ('GET', ['posts']) => {'data': posts, 'nextCursor': null, 'hasMore': false},
      ('GET', ['posts', final id]) => {
          ...posts.firstWhere((p) => p['id'] == id),
          'location': _place,
        },
      ('GET', ['comments', final id]) => comments[id] ?? [],
      ('POST', ['comments', final id]) => () {
          final c = _comment(o.data['body'] as String, user: 'demo', at: '2025-06-09T00:00:00.000Z');
          comments[id] = [c, ...?comments[id]];
          return c;
        }(),
      _ => throw StateError('unexpected ${o.method} ${o.path}'),
    };
    handler.resolve(Response(requestOptions: o, data: data, statusCode: 200));
  }
}

void main() {
  late _Api api;

  Future<void> pumpPhoto(WidgetTester tester, String postId) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    api = _Api();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(Dio()..interceptors.add(api)),
        photoSchemeProvider.overrideWith((ref, key) async => null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: PostDetailScreen(postId: postId)),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> swipeTo(WidgetTester tester, {required bool newer}) async {
    await tester.fling(find.byType(PageView), Offset(newer ? -400 : 400, 0), 1500);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('opens on the tapped photo with its capture time on top', (tester) async {
    await pumpPhoto(tester, 'p2023');

    expect(find.bySemanticsLabel(RegExp('^Foto 2 dari 3, diambil')), findsOneWidget);
    expect(find.textContaining('Diambil 11 Mei 2023 pukul'), findsOneWidget);
    expect(find.text('Kabut pagi'), findsOneWidget);
  });

  testWidgets('comments read oldest first', (tester) async {
    await pumpPhoto(tester, 'p2023');

    final question = tester.getTopLeft(find.textContaining('Patak Banteng')).dy;
    final answer = tester.getTopLeft(find.textContaining('3 jam naik')).dy;
    expect(question, lessThan(answer));
    expect(find.text('2 komentar'), findsOneWidget);
  });

  testWidgets('swiping moves through the place in time order', (tester) async {
    await pumpPhoto(tester, 'p2023');

    await swipeTo(tester, newer: true);
    expect(find.bySemanticsLabel(RegExp('^Foto 3 dari 3')), findsOneWidget);
    expect(find.text('Sindoro dari puncak'), findsOneWidget);
    expect(find.text('Belum ada komentar. Tulis yang pertama di bawah.'), findsOneWidget);
    expect(find.text('0 komentar'), findsNothing);

    await swipeTo(tester, newer: false);
    await swipeTo(tester, newer: false);
    expect(find.bySemanticsLabel(RegExp('^Foto 1 dari 3')), findsOneWidget);
    expect(find.textContaining('2019'), findsWidgets);
  });

  testWidgets('a sent comment lands at the bottom and clears the field', (tester) async {
    await pumpPhoto(tester, 'p2023');

    await tester.enterText(find.byType(TextField), 'Mantap');
    await tester.pump();
    await tester.tap(find.byTooltip('Kirim komentar'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('3 komentar'), findsOneWidget);
    final sent = tester.getTopLeft(find.textContaining('Mantap')).dy;
    final answer = tester.getTopLeft(find.textContaining('3 jam naik')).dy;
    expect(sent, greaterThan(answer));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('send is off until there is text, and screen readers can tap it', (tester) async {
    await pumpPhoto(tester, 'p2023');
    final send = find.byTooltip('Kirim komentar');

    expect(tester.getSemantics(send), isSemantics(isEnabled: false));
    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.pump();
    expect(tester.getSemantics(send), isSemantics(isEnabled: true, hasTapAction: true));
  });

  testWidgets('only the photo in view is read out, not the peeking ones', (tester) async {
    await pumpPhoto(tester, 'p2023');

    expect(find.bySemanticsLabel(RegExp(r'^Foto \d dari 3')), findsOneWidget);
  });

  testWidgets('has no menu button that does nothing', (tester) async {
    await pumpPhoto(tester, 'p2023');

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('a failed load says so and can retry', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    api = _Api()..fail = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(Dio()..interceptors.add(api)),
        photoSchemeProvider.overrideWith((ref, key) async => null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const PostDetailScreen(postId: 'p2023')),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Foto ini gagal dimuat.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Kabut pagi'), findsOneWidget);
  });
}

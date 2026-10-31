import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/post/data/post_repository.dart';

Map<String, dynamic> _postJson(String takenAt) => {
      'id': 'p1',
      'media_url': 'asset:assets/demo/prau/prau-01.jpg',
      'media_type': 'photo',
      'caption': null,
      'taken_at': takenAt,
      'uploaded_at': '2025-06-01T00:00:00.000Z',
      'user_id': 'u1',
      'location_id': 'l1',
    };

void main() {
  test('taken_at from the API is shown in local time', () {
    final post = PostModel.fromJson(_postJson('2025-05-27T22:43:36.000Z'));

    expect(post.takenAt.isUtc, isFalse);
    expect(post.takenAt.isAtSameMomentAs(DateTime.utc(2025, 5, 27, 22, 43, 36)),
        isTrue);
  });

  test('upload sends taken_at as UTC with a Z suffix', () async {
    final dir = Directory.systemTemp.createTempSync('tepilog_post_');
    final photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    String? sent;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
        sent = {for (final f in (o.data as FormData).fields) f.key: f.value}['taken_at'];
        h.reject(DioException(requestOptions: o));
      }));

    // EXIF dates are wall-clock times on the phone, so they parse as local.
    final takenAt = DateTime(2025, 5, 28, 5, 43, 36);
    await expectLater(
      PostRepository(dio).createPost(
          photo: photo, latitude: -7.1867, longitude: 109.9228, takenAt: takenAt),
      throwsA(isA<DioException>()),
    );

    expect(sent, endsWith('Z'));
    expect(DateTime.parse(sent!).isAtSameMomentAs(takenAt), isTrue);
    dir.deleteSync(recursive: true);
  });
}

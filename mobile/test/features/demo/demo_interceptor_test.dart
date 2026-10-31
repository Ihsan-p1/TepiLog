import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_interceptor.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/post/data/post_repository.dart';

import 'demo_test_helpers.dart';

void main() {
  late TestStoreEnv env;
  late DemoStore store;
  late Dio dio;

  setUp(() async {
    env = await TestStoreEnv.create();
    store = await env.open();
    // Unreachable host: any request that leaks past the interceptor fails.
    dio = Dio(BaseOptions(baseUrl: 'http://unreachable.invalid/api'))
      ..interceptors.add(DemoInterceptor(store));
  });

  tearDown(() async => Hive.close());

  Future<int> status(Future<Response> call) async {
    try {
      return (await call).statusCode!;
    } on DioException catch (e) {
      return e.response?.statusCode ?? -1;
    }
  }

  File tempPhoto() =>
      File('${env.root.path}/upload.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

  test('every route answers without the network', () async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(tempPhoto().path, filename: 'upload.jpg'),
      'latitude': '-7.1867',
      'longitude': '109.9228',
      'taken_at': '2025-05-28T06:00:00.000',
    });
    final created = await dio.post('/posts', data: form);
    final postId = created.data['id'] as String;
    final comment = await dio.post('/comments/$postId', data: {'body': ' Bagus '});

    final expected = <Future<Response> Function(), int>{
      () => dio.get('/locations', queryParameters: {'lat': 0, 'lng': 0}): 200,
      () => dio.get('/locations/trending', queryParameters: {'lat': 0, 'lng': 0}): 200,
      () => dio.get('/locations/search', queryParameters: {'q': 'prau'}): 200,
      () => dio.get('/locations/seed-loc-prau'): 200,
      () => dio.get('/locations/nope'): 404,
      () => dio.get('/posts', queryParameters: {'location_id': 'seed-loc-prau'}): 200,
      () => dio.get('/posts'): 400,
      () => dio.post('/posts', data: FormData.fromMap({'latitude': '1'})): 400,
      () => dio.get('/posts/$postId'): 200,
      () => dio.get('/posts/nope'): 404,
      () => dio.get('/comments/$postId'): 200,
      () => dio.post('/comments/$postId', data: {'body': '   '}): 400,
      () => dio.delete('/comments/${comment.data['id']}'): 200,
      () => dio.get('/saved'): 200,
      () => dio.post('/saved/seed-loc-prau'): 200,
      () => dio.get('/saved/seed-loc-prau/check'): 200,
      () => dio.get('/users/me'): 200,
      () => dio.get('/users/me/posts'): 200,
      () => dio.delete('/posts/$postId'): 200,
      () => dio.delete('/posts/nope'): 404,
    };

    expect(created.statusCode, 201);
    expect(comment.statusCode, 201);
    expect(comment.data['body'], 'Bagus');
    for (final entry in expected.entries) {
      expect(await status(entry.key()), entry.value);
    }
  });

  test('responses are plain JSON like a real Dio response', () async {
    final res = await dio.get('/comments/seed-post-01');
    final list = res.data as List;
    expect(() => list.insert(0, <String, dynamic>{'id': 'x'}), returnsNormally);
    final saved = await dio.post('/saved/seed-loc-prau');
    expect(saved.data, {'saved': true});
    final check = await dio.get('/saved/seed-loc-prau/check');
    expect(check.data, {'saved': true});
  });

  test('PostRepository.getPostsByLocation parses the demo feed', () async {
    final feed = await PostRepository(dio).getPostsByLocation(locationId: 'seed-loc-prau');
    expect(feed.posts, hasLength(3));
    expect(feed.posts.first.takenAt.isAfter(feed.posts.last.takenAt), isTrue);
    expect(feed.posts.first.user?.username, 'tomorrow');
    expect(feed.hasMore, isFalse);
  });

  test('LocationRepository.getNearbyLocations parses demo locations', () async {
    final locations =
        await LocationRepository(dio).getNearbyLocations(lat: 0, lng: 0);
    expect(locations, hasLength(1));
    expect(locations.single.postCount, 3);
  });

  test('PostRepository.createPost with no EXIF date still creates a post', () async {
    final post = await PostRepository(dio).createPost(
      photo: tempPhoto(),
      latitude: -7.1867,
      longitude: 109.9228,
    );
    expect(post.takenAt.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    expect(post.locationId, 'seed-loc-prau');
  });

  test('unknown route is 404', () async {
    expect(await status(dio.post('/auth/refresh', data: {})), 404);
  });

  test('deleting a seed post is 403', () async {
    expect(await status(dio.delete('/posts/seed-post-01')), 403);
  });
}

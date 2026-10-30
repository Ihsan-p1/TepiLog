import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';

import 'demo_test_helpers.dart';

const _prauLat = -7.1867;
const _prauLng = 109.9228;
const _metersPerDegreeLat = 111195.0;

Future<Map<String, dynamic>> _upload(DemoStore store, double metersNorth,
        {String? name}) =>
    store.createPost(
      bytes: [1, 2, 3],
      filename: 'photo.jpg',
      latitude: _prauLat + metersNorth / _metersPerDegreeLat,
      longitude: _prauLng,
      takenAt: DateTime.utc(2025, 5, 28, 2),
      locationName: name,
    );

void main() {
  late TestStoreEnv env;
  late DemoStore store;

  setUp(() async {
    env = await TestStoreEnv.create();
    store = await env.open();
  });

  tearDown(() async => Hive.close());

  test('createPost at 49 m joins the existing location', () async {
    final post = await _upload(store, 49);

    expect(post['location']['id'], 'seed-loc-prau');
    expect(store.locations(), hasLength(1));
    expect(store.locations().single['post_count'], 4);
  });

  test('createPost at 51 m without a name creates Lokasi Baru', () async {
    await _upload(store, 51);

    final locations = store.locations();
    expect(locations, hasLength(2));
    expect(locations.where((l) => l['name'] == 'Lokasi Baru'), hasLength(1));
  });

  test('postsByLocation orders by taken_at desc and pages with a cursor', () {
    final first = store.postsByLocation('seed-loc-prau', limit: 2);
    expect(first.data.map((p) => p['id']), ['seed-post-02', 'seed-post-03']);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor, 'seed-post-03');

    final second = store.postsByLocation('seed-loc-prau',
        cursor: first.nextCursor, limit: 2);
    expect(second.data.map((p) => p['id']), ['seed-post-01']);
    expect(second.hasMore, isFalse);
    expect(second.nextCursor, isNull);
  });

  test('deletePost refuses seed posts and removes visitor posts with their file',
      () async {
    expect(await store.deletePost('seed-post-01'), DemoResult.forbidden);

    final post = await _upload(store, 10);
    final file = File((post['media_url'] as String).substring('file:'.length));
    expect(file.existsSync(), isTrue);

    expect(await store.deletePost(post['id'] as String), DemoResult.ok);
    expect(file.existsSync(), isFalse);
    expect(await store.deletePost(post['id'] as String), DemoResult.notFound);
  });

  test('data survives closing and reopening the box', () async {
    final post = await _upload(store, 10);
    await Hive.close();

    final reopened = await env.open();
    final again = reopened.post(post['id'] as String);
    expect(again, isNotNull);
    final path = (again!['media_url'] as String).substring('file:'.length);
    expect(File(path).existsSync(), isTrue);
  });

  test('reset restores the seed only', () async {
    final post = await _upload(store, 10);
    await store.addComment(post['id'] as String, 'Bagus');
    await store.toggleSaved('seed-loc-prau');

    await store.reset();
    await store.ensureSeeded();

    expect(store.postsByLocation('seed-loc-prau').data, hasLength(3));
    expect(store.myPosts(), isEmpty);
    expect(store.saved(), isEmpty);
    expect(store.comments('seed-post-01'), isEmpty);
    expect(env.uploads.existsSync() ? env.uploads.listSync() : [], isEmpty);
  });

  test('searchLocations ignores one-letter queries', () {
    expect(store.searchLocations('G'), isEmpty);
    expect(store.searchLocations('prau'), hasLength(1));
  });
}

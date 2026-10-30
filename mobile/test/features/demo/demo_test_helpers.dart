import 'dart:io';

import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';

/// Small seed shared by the demo tests: one location, three posts by the
/// seed photographer, taken at different times.
Map<String, dynamic> testSeed() => {
      'users': [
        {
          'id': 'seed-user-tomorrow',
          'email': 'tomorrow@demo.local',
          'username': 'tomorrow',
          'avatar_url': null,
          'created_at': '2025-06-01T00:00:00.000Z',
        }
      ],
      'locations': [
        {
          'id': 'seed-loc-prau',
          'name': 'Gunung Prau',
          'latitude': -7.1867,
          'longitude': 109.9228,
          'created_at': '2025-06-01T00:00:00.000Z',
        }
      ],
      'posts': [
        for (final (i, t) in [
          '2025-05-27T22:15:05.000Z',
          '2025-05-28T01:34:09.000Z',
          '2025-05-27T22:42:58.000Z',
        ].indexed)
          {
            'id': 'seed-post-0${i + 1}',
            'user_id': 'seed-user-tomorrow',
            'location_id': 'seed-loc-prau',
            'media_url': 'asset:assets/demo/prau/prau-0${i + 1}.jpg',
            'media_type': 'photo',
            'caption': null,
            'taken_at': t,
            'uploaded_at': '2025-06-01T00:00:00.000Z',
          }
      ],
    };

class TestStoreEnv {
  TestStoreEnv._(this.root, this.uploads);

  final Directory root;
  final Directory uploads;
  static int _boxSeq = 0;
  late String boxName;

  static Future<TestStoreEnv> create() async {
    final root = Directory.systemTemp.createTempSync('tepilog_demo_');
    Hive.init(root.path);
    final env = TestStoreEnv._(root, Directory('${root.path}/uploads'));
    env.boxName = 'demo_test_${_boxSeq++}';
    return env;
  }

  Future<DemoStore> open() async {
    final box = await Hive.openBox(boxName);
    final store = DemoStore(
      box: box,
      loadSeed: () async => testSeed(),
      uploadsDir: () async => uploads,
    );
    await store.ensureSeeded();
    return store;
  }
}

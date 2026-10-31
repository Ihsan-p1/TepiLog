import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:tepilog/features/demo/data/demo_geo.dart';

enum DemoResult { ok, notFound, forbidden }

/// Local data behind demo mode. Every list is kept as JSON in one Hive box,
/// shaped like the rows the backend returns, so the demo interceptor can
/// answer with the same JSON as the real API.
class DemoStore {
  DemoStore({
    required Box box,
    required Future<Map<String, dynamic>> Function() loadSeed,
    required Future<Directory> Function() uploadsDir,
  })  : _box = box,
        _loadSeed = loadSeed,
        _uploadsDir = uploadsDir;

  final Box _box;
  final Future<Map<String, dynamic>> Function() _loadSeed;
  final Future<Directory> Function() _uploadsDir;

  static const visitorId = 'demo-visitor';
  static const Map<String, dynamic> visitorJson = {
    'id': visitorId,
    'email': 'demo@demo.local',
    'username': 'demo',
    'avatar_url': null,
    'created_at': '2025-06-01T00:00:00.000Z',
  };

  /// Same radius as findOrCreateLocation in the backend's geo.service.js.
  static const mergeRadiusMeters = 50.0;

  static const _dataKeys = ['users', 'locations', 'posts', 'comments', 'saved'];
  static int _idSeq = 0;

  bool get isActive => _box.get('active') == true;
  Future<void> setActive(bool value) => _box.put('active', value);

  Future<void> ensureSeeded() async {
    if (_box.get('locations') != null) return;
    final seed = await _loadSeed();
    await _write('users', [..._list(seed['users']), visitorJson]);
    await _write('locations', _list(seed['locations']));
    await _write('posts', _list(seed['posts']));
    await _write('comments', []);
    await _write('saved', []);
  }

  Future<void> reset() async {
    await _box.deleteAll(_dataKeys);
    final dir = await _uploadsDir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  // ---- Locations ----

  List<Map<String, dynamic>> locations() =>
      _read('locations').map(_withPostCount).toList();

  Map<String, dynamic>? location(String id) {
    final loc = _find('locations', id);
    if (loc == null) return null;
    final withCount = _withPostCount(loc);
    return {
      ...withCount,
      '_count': {'posts': withCount['post_count']},
    };
  }

  List<Map<String, dynamic>> searchLocations(String q) {
    if (q.length < 2) return [];
    final needle = q.toLowerCase();
    final hits = locations()
        .where((l) => (l['name'] as String? ?? '').toLowerCase().contains(needle))
        .toList()
      ..sort((a, b) => (b['post_count'] as int).compareTo(a['post_count'] as int));
    return hits.take(5).toList();
  }

  // ---- Posts ----

  ({List<Map<String, dynamic>> data, String? nextCursor, bool hasMore})
      postsByLocation(String locationId, {String? cursor, int limit = 20}) {
    final all = _read('posts').where((p) => p['location_id'] == locationId).toList()
      ..sort(_byTakenAtDesc);
    var start = 0;
    if (cursor != null) {
      final i = all.indexWhere((p) => p['id'] == cursor);
      start = i < 0 ? all.length : i + 1;
    }
    final rest = all.skip(start).toList();
    final hasMore = rest.length > limit;
    final data = rest.take(limit).map(_withUserAndCount).toList();
    return (
      data: data,
      nextCursor: hasMore ? data.last['id'] as String : null,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic>? post(String id) {
    final p = _find('posts', id);
    if (p == null) return null;
    return {
      ..._withUserAndCount(p),
      'location': _locationSummary(p['location_id'] as String),
      'comments': comments(id).take(10).toList(),
    };
  }

  Future<Map<String, dynamic>> createPost({
    required List<int> bytes,
    required String filename,
    required double latitude,
    required double longitude,
    String? caption,
    required DateTime takenAt,
    String? locationName,
  }) async {
    final locationId = await _findOrCreateLocation(latitude, longitude, locationName);
    final id = _newId();
    final ext = filename.contains('.') ? filename.split('.').last : 'jpg';
    final dir = await _uploadsDir();
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$id.$ext');
    await file.writeAsBytes(bytes, flush: true);

    final row = {
      'id': id,
      'user_id': visitorId,
      'location_id': locationId,
      'media_url': 'file:${file.path}',
      'media_type': 'photo',
      'caption': (caption == null || caption.isEmpty) ? null : caption,
      'taken_at': takenAt.toUtc().toIso8601String(),
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _write('posts', [..._read('posts'), row]);
    return {
      ...row,
      'user': _userSummary(visitorId),
      'location': _locationSummary(locationId),
    };
  }

  Future<DemoResult> deletePost(String id) async {
    final p = _find('posts', id);
    if (p == null) return DemoResult.notFound;
    if (p['user_id'] != visitorId) return DemoResult.forbidden;
    final url = p['media_url'] as String;
    if (url.startsWith('file:')) {
      final file = File(url.substring('file:'.length));
      if (file.existsSync()) await file.delete();
    }
    await _write('posts', _read('posts').where((x) => x['id'] != id).toList());
    await _write('comments', _read('comments').where((c) => c['post_id'] != id).toList());
    return DemoResult.ok;
  }

  // ---- Comments ----

  List<Map<String, dynamic>> comments(String postId) {
    final list = _read('comments').where((c) => c['post_id'] == postId).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map((c) => {...c, 'user': _userSummary(c['user_id'] as String)}).toList();
  }

  Future<Map<String, dynamic>> addComment(String postId, String body) async {
    final row = {
      'id': _newId(),
      'post_id': postId,
      'user_id': visitorId,
      'body': body,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _write('comments', [..._read('comments'), row]);
    return {...row, 'user': _userSummary(visitorId)};
  }

  Future<DemoResult> deleteComment(String id) async {
    final c = _find('comments', id);
    if (c == null) return DemoResult.notFound;
    if (c['user_id'] != visitorId) return DemoResult.forbidden;
    await _write('comments', _read('comments').where((x) => x['id'] != id).toList());
    return DemoResult.ok;
  }

  // ---- Saved locations ----

  bool isSaved(String locationId) =>
      _read('saved').any((s) => s['location_id'] == locationId);

  Future<bool> toggleSaved(String locationId) async {
    final saved = _read('saved');
    if (isSaved(locationId)) {
      await _write('saved', saved.where((s) => s['location_id'] != locationId).toList());
      return false;
    }
    await _write('saved', [
      ...saved,
      {'location_id': locationId, 'saved_at': DateTime.now().toUtc().toIso8601String()},
    ]);
    return true;
  }

  List<Map<String, dynamic>> saved() {
    final list = _read('saved')
      ..sort((a, b) => (b['saved_at'] as String).compareTo(a['saved_at'] as String));
    return [
      for (final s in list)
        if (_find('locations', s['location_id'] as String) case final loc?)
          {..._withPostCount(loc), 'saved_at': s['saved_at']},
    ];
  }

  // ---- Profile ----

  Map<String, dynamic> profile() {
    final mine = _read('posts').where((p) => p['user_id'] == visitorId).toList();
    final savedCount = _read('saved').length;
    return {
      ...visitorJson,
      '_count': {'posts': mine.length, 'saved_locations': savedCount},
      'stats': {
        'posts': mine.length,
        'locations': mine.map((p) => p['location_id']).toSet().length,
        'saved': savedCount,
      },
    };
  }

  List<Map<String, dynamic>> myPosts() {
    final mine = _read('posts').where((p) => p['user_id'] == visitorId).toList()
      ..sort((a, b) => (b['uploaded_at'] as String).compareTo(a['uploaded_at'] as String));
    return mine
        .map((p) => {
              ..._withUserAndCount(p),
              'location': _locationSummary(p['location_id'] as String),
            })
        .toList();
  }

  // ---- Internals ----

  Future<String> _findOrCreateLocation(double lat, double lng, String? name) async {
    Map<String, dynamic>? nearest;
    var best = double.infinity;
    for (final l in _read('locations')) {
      final d = distanceMeters(lat, lng, (l['latitude'] as num).toDouble(),
          (l['longitude'] as num).toDouble());
      if (d <= mergeRadiusMeters && d < best) {
        best = d;
        nearest = l;
      }
    }
    if (nearest != null) return nearest['id'] as String;

    final id = _newId();
    await _write('locations', [
      ..._read('locations'),
      {
        'id': id,
        'name': name ?? 'Lokasi Baru',
        'latitude': lat,
        'longitude': lng,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
    return id;
  }

  Map<String, dynamic> _withPostCount(Map<String, dynamic> loc) => {
        ...loc,
        'post_count': _read('posts').where((p) => p['location_id'] == loc['id']).length,
      };

  Map<String, dynamic> _withUserAndCount(Map<String, dynamic> p) => {
        ...p,
        'user': _userSummary(p['user_id'] as String),
        '_count': {'comments': _read('comments').where((c) => c['post_id'] == p['id']).length},
      };

  Map<String, dynamic>? _userSummary(String id) {
    final u = _find('users', id);
    if (u == null) return null;
    return {'id': u['id'], 'username': u['username'], 'avatar_url': u['avatar_url']};
  }

  Map<String, dynamic>? _locationSummary(String id) {
    final l = _find('locations', id);
    if (l == null) return null;
    return {'id': l['id'], 'name': l['name'], 'latitude': l['latitude'], 'longitude': l['longitude']};
  }

  static int _byTakenAtDesc(Map<String, dynamic> a, Map<String, dynamic> b) =>
      DateTime.parse(b['taken_at'] as String).compareTo(DateTime.parse(a['taken_at'] as String));

  Map<String, dynamic>? _find(String key, String id) {
    for (final row in _read(key)) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  String _newId() => 'demo-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  List<Map<String, dynamic>> _read(String key) {
    final raw = _box.get(key) as String?;
    return raw == null ? [] : _list(jsonDecode(raw));
  }

  Future<void> _write(String key, List<Map<String, dynamic>> rows) =>
      _box.put(key, jsonEncode(rows));

  static List<Map<String, dynamic>> _list(Object? value) =>
      [for (final e in (value as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
}

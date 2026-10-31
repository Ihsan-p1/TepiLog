import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';

typedef _Reply = ({int status, Object? body});

/// Answers every API request from [DemoStore] while demo mode is on.
///
/// It never calls `handler.next`, so no request reaches the network.
/// Replies mirror the JSON and error messages of the backend controllers.
class DemoInterceptor extends Interceptor {
  DemoInterceptor(this.store);

  final DemoStore store;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final reply = await _route(options);
      // Round-trip through JSON so screens get the same plain List/Map
      // types a real Dio response would give them.
      final response = Response(
        requestOptions: options,
        statusCode: reply.status,
        data: jsonDecode(jsonEncode(reply.body)),
      );
      if (reply.status >= 400) {
        handler.reject(DioException.badResponse(
          statusCode: reply.status,
          requestOptions: options,
          response: response,
        ));
      } else {
        handler.resolve(response);
      }
    } catch (e, st) {
      handler.reject(DioException(requestOptions: options, error: e, stackTrace: st));
    }
  }

  Future<_Reply> _route(RequestOptions o) async {
    final seg = Uri.parse(o.path).pathSegments.where((s) => s.isNotEmpty).toList();
    final q = o.queryParameters;

    switch ((o.method.toUpperCase(), seg)) {
      case ('GET', ['locations']):
        return _ok(store.locations());
      case ('GET', ['locations', 'trending']):
        final list = store.locations()
          ..sort((a, b) => (b['post_count'] as int).compareTo(a['post_count'] as int));
        return _ok(list);
      case ('GET', ['locations', 'search']):
        return _ok(store.searchLocations('${q['q'] ?? ''}'));
      case ('GET', ['locations', final id]):
        return _orNotFound(store.location(id), 'Lokasi tidak ditemukan');

      case ('GET', ['posts']):
        final locationId = q['location_id'];
        if (locationId == null || '$locationId'.isEmpty) {
          return _error(400, 'location_id wajib diisi');
        }
        final limit = (int.tryParse('${q['limit']}') ?? 20).clamp(1, 100);
        final page = store.postsByLocation('$locationId',
            cursor: q['cursor'] as String?, limit: limit);
        return _ok({'data': page.data, 'nextCursor': page.nextCursor, 'hasMore': page.hasMore});
      case ('POST', ['posts']):
        return _createPost(o.data);
      case ('GET', ['posts', final id]):
        return _orNotFound(store.post(id), 'Post tidak ditemukan');
      case ('DELETE', ['posts', final id]):
        return _deleted(await store.deletePost(id), 'Post berhasil dihapus',
            'Post tidak ditemukan', 'Tidak diizinkan menghapus post ini');

      case ('GET', ['comments', final postId]):
        return _ok(store.comments(postId));
      case ('POST', ['comments', final postId]):
        final body = (o.data is Map ? o.data['body'] : null);
        final text = body is String ? body.trim() : '';
        if (text.isEmpty) return _error(400, 'Komentar tidak boleh kosong');
        return (status: 201, body: await store.addComment(postId, text));
      case ('DELETE', ['comments', final id]):
        return _deleted(await store.deleteComment(id), 'Komentar berhasil dihapus',
            'Komentar tidak ditemukan', 'Tidak diizinkan menghapus komentar ini');

      case ('GET', ['saved']):
        return _ok(store.saved());
      case ('POST', ['saved', final locationId]):
        return _ok({'saved': await store.toggleSaved(locationId)});
      case ('GET', ['saved', final locationId, 'check']):
        return _ok({'saved': store.isSaved(locationId)});

      case ('GET', ['users', 'me']):
        return _ok(store.profile());
      case ('GET', ['users', 'me', 'posts']):
        return _ok(store.myPosts());
    }
    return _error(404, 'Tidak tersedia di mode demo');
  }

  Future<_Reply> _createPost(Object? data) async {
    if (data is! FormData) return _error(400, 'File foto wajib diupload');
    final photo = data.files.where((f) => f.key == 'photo').firstOrNull?.value;
    if (photo == null) return _error(400, 'File foto wajib diupload');

    final fields = {for (final f in data.fields) f.key: f.value};
    final lat = double.tryParse(fields['latitude'] ?? '');
    final lng = double.tryParse(fields['longitude'] ?? '');
    if (lat == null || lng == null) {
      return _error(400, 'Koordinat (latitude, longitude) wajib diisi');
    }

    final bytes = <int>[];
    await for (final chunk in photo.finalize()) {
      bytes.addAll(chunk);
    }
    final post = await store.createPost(
      bytes: bytes,
      filename: photo.filename ?? 'photo.jpg',
      latitude: lat,
      longitude: lng,
      caption: fields['caption'],
      takenAt: DateTime.tryParse(fields['taken_at'] ?? '') ?? DateTime.now(),
      locationName: fields['location_name'],
    );
    return (status: 201, body: post);
  }

  static _Reply _ok(Object? body) => (status: 200, body: body);

  static _Reply _error(int status, String message) =>
      (status: status, body: {'error': message});

  static _Reply _orNotFound(Object? body, String message) =>
      body == null ? _error(404, message) : _ok(body);

  static _Reply _deleted(DemoResult result, String ok, String notFound, String forbidden) =>
      switch (result) {
        DemoResult.ok => _ok({'message': ok}),
        DemoResult.notFound => _error(404, notFound),
        DemoResult.forbidden => _error(403, forbidden),
      };
}

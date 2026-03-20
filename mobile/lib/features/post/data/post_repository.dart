import 'dart:io';
import 'package:dio/dio.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:tepilog/shared/constants/api_constants.dart';

class PostModel {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime takenAt;
  final DateTime uploadedAt;
  final String userId;
  final String locationId;
  final PostUser? user;
  final PostLocation? location;
  final int commentCount;

  PostModel({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.takenAt,
    required this.uploadedAt,
    required this.userId,
    required this.locationId,
    this.user,
    this.location,
    this.commentCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      caption: json['caption'],
      takenAt: DateTime.parse(json['taken_at']),
      uploadedAt: DateTime.parse(json['uploaded_at']),
      userId: json['user_id'],
      locationId: json['location_id'],
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      location: json['location'] != null ? PostLocation.fromJson(json['location']) : null,
      commentCount: json['_count']?['comments'] ?? 0,
    );
  }
}

class PostUser {
  final String id;
  final String username;
  final String? avatarUrl;

  PostUser({required this.id, required this.username, this.avatarUrl});

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class PostLocation {
  final String id;
  final String? name;
  final double latitude;
  final double longitude;

  PostLocation({required this.id, this.name, required this.latitude, required this.longitude});

  factory PostLocation.fromJson(Map<String, dynamic> json) {
    return PostLocation(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class PostRepository {
  final Dio _dio;

  PostRepository(this._dio);

  /// Extract EXIF DateTimeOriginal from an image file
  Future<DateTime?> extractExifDate(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.containsKey('EXIF DateTimeOriginal')) {
        final dateStr = data['EXIF DateTimeOriginal']!.printable;
        // Format EXIF: "2024:03:15 14:30:00"
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0].replaceAll(':', '-');
          return DateTime.tryParse('$datePart ${parts[1]}');
        }
      }
    } catch (e) {
      debugPrint('EXIF extraction error: $e');
    }
    return null;
  }

  /// Upload post with photo
  Future<PostModel> createPost({
    required File photo,
    required double latitude,
    required double longitude,
    String? caption,
    DateTime? takenAt,
    String? locationName,
  }) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photo.path, filename: photo.path.split('/').last),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (caption != null) 'caption': caption,
      'taken_at': (takenAt ?? DateTime.now()).toIso8601String(),
      if (locationName != null) 'location_name': locationName,
    });

    final response = await _dio.post(
      ApiConstants.posts,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return PostModel.fromJson(response.data);
  }

  /// Get posts by location (cursor pagination)
  Future<PostFeedResponse> getPostsByLocation({
    required String locationId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.posts,
      queryParameters: {
        'location_id': locationId,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final List data = response.data['data'];
    return PostFeedResponse(
      posts: data.map((json) => PostModel.fromJson(json)).toList(),
      nextCursor: response.data['nextCursor'],
      hasMore: response.data['hasMore'] ?? false,
    );
  }

  /// Get post detail
  Future<PostModel> getPostDetail(String id) async {
    final response = await _dio.get('${ApiConstants.posts}/$id');
    return PostModel.fromJson(response.data);
  }

  /// Delete post
  Future<void> deletePost(String id) async {
    await _dio.delete('${ApiConstants.posts}/$id');
  }
}

class PostFeedResponse {
  final List<PostModel> posts;
  final String? nextCursor;
  final bool hasMore;

  PostFeedResponse({
    required this.posts,
    this.nextCursor,
    required this.hasMore,
  });
}

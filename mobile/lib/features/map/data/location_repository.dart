import 'package:dio/dio.dart';
import 'package:tepilog/shared/constants/api_constants.dart';

class Location {
  final String id;
  final String? name;
  final double latitude;
  final double longitude;
  final int postCount;
  final double? distance;

  Location({
    required this.id,
    this.name,
    required this.latitude,
    required this.longitude,
    required this.postCount,
    this.distance,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      postCount: json['post_count'] ?? 0,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }
}

class LocationRepository {
  final Dio _dio;

  LocationRepository(this._dio);

  Future<List<Location>> getNearbyLocations({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    final response = await _dio.get(
      ApiConstants.locations,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
      },
    );

    final List data = response.data;
    return data.map((json) => Location.fromJson(json)).toList();
  }

  Future<Location> getLocationDetail(String id) async {
    final response = await _dio.get('${ApiConstants.locations}/$id');
    return Location.fromJson(response.data);
  }

  Future<List<Location>> getTrendingLocations({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get(
      ApiConstants.trending,
      queryParameters: {
        'lat': lat,
        'lng': lng,
      },
    );

    final List data = response.data;
    return data.map((json) => Location.fromJson(json)).toList();
  }
}

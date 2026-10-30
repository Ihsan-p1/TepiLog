import 'dart:math';

const double _earthRadiusMeters = 6371000;

/// Great-circle distance between two points, in meters (haversine).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  double rad(double deg) => deg * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * _earthRadiusMeters * asin(sqrt(a));
}

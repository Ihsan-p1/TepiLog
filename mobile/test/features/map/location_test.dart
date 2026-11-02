import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/map/data/location_repository.dart';

void main() {
  test('fromJson reads cover and taken_at span', () {
    final loc = Location.fromJson({
      'id': 'a',
      'name': 'Gunung Prau',
      'latitude': -7.1867,
      'longitude': 109.9228,
      'post_count': 2,
      'cover_url': 'https://img/new.jpg',
      'first_taken_at': '2019-08-17T22:00:00.000Z',
      'last_taken_at': '2025-05-27T22:15:00.000Z',
    });

    expect(loc.coverUrl, 'https://img/new.jpg');
    expect(loc.firstTakenAt, DateTime.utc(2019, 8, 17, 22));
    expect(loc.lastTakenAt, DateTime.utc(2025, 5, 27, 22, 15));
  });

  test('fromJson leaves cover and span null when absent', () {
    final loc = Location.fromJson({
      'id': 'a',
      'latitude': 0,
      'longitude': 0,
      'post_count': 0,
    });

    expect(loc.coverUrl, isNull);
    expect(loc.firstTakenAt, isNull);
    expect(loc.lastTakenAt, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/demo/data/demo_geo.dart';

void main() {
  test('distance from Prau to a point 0.0005 degrees north is about 55.6 m', () {
    final d = distanceMeters(-7.1867, 109.9228, -7.1862, 109.9228);
    expect(d, closeTo(55.6, 1.0));
  });

  test('distance from a point to itself is zero', () {
    expect(distanceMeters(-7.1867, 109.9228, -7.1867, 109.9228), 0);
  });
}

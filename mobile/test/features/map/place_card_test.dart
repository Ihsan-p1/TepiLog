import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/features/map/presentation/widgets/photo_pin.dart';
import 'package:tepilog/features/map/presentation/widgets/place_card.dart';

Location _place({int count = 20, DateTime? first, DateTime? last}) => Location(
      id: 'prau',
      name: 'Gunung Prau',
      latitude: -7.1867,
      longitude: 109.9228,
      postCount: count,
      coverUrl: 'asset:assets/demo/prau/prau-01.jpg',
      firstTakenAt: first ?? DateTime.utc(2019, 8, 17),
      lastTakenAt: last ?? DateTime.utc(2025, 5, 27),
    );

MapState _state({List<Location> locations = const [], bool loading = false, String? error}) =>
    MapState(
      cameraPosition: const LatLng(0, 0),
      locations: locations,
      isLoading: loading,
      error: error,
    );

void main() {
  test('place line names photo count and year span', () {
    expect(placeLine(_place()), '20 foto · 2019–2025');
    expect(
      placeLine(_place(count: 1, first: DateTime.utc(2025, 5, 27))),
      '1 foto · 2025',
    );
  });

  test('count line follows the map state', () {
    expect(mapCountLine(_state(loading: true)), 'Memuat tempat…');
    expect(mapCountLine(_state()), 'Belum ada foto di area ini');
    expect(mapCountLine(_state(locations: [_place(), _place()])), '2 tempat di area ini');
    expect(mapCountLine(_state(error: 'Gagal memuat peta')), 'Gagal memuat peta');
  });

  testWidgets('card shows the place and opens it on tap', (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PlaceCard(location: _place(), onOpen: () => opened++),
      ),
    ));

    expect(find.text('Gunung Prau'), findsOneWidget);
    expect(find.text('20 foto · 2019–2025'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('Buka Gunung Prau')));
    expect(opened, 1);
  });

  testWidgets('pin bitmap is drawn at device pixels with room for the count',
      (tester) async {
    await tester.runAsync(() async {
      final png = await paintPhotoPin(
        photo: const AssetImage('assets/demo/prau/prau-01.jpg'),
        count: 20,
        ring: const Color(0xFFE07A2E),
        onRing: Colors.white,
        selected: false,
        devicePixelRatio: 2,
      );
      final codec = await ui.instantiateImageCodec(png);
      final frame = (await codec.getNextFrame()).image;

      expect(frame.width, (PhotoPinSize.normal.width * 2).round());
      expect(frame.height, (PhotoPinSize.normal.height * 2).round());
      expect(frame.height, greaterThan(frame.width));
    });
  });
}

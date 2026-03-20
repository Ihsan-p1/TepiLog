import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

class MapState {
  final LatLng cameraPosition;
  final List<Location> locations;
  final bool isLoading;
  final String? error;

  MapState({
    required this.cameraPosition,
    this.locations = const [],
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    LatLng? cameraPosition,
    List<Location>? locations,
    bool? isLoading,
    String? error,
  }) {
    return MapState(
      cameraPosition: cameraPosition ?? this.cameraPosition,
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    return MapState(
      cameraPosition: const LatLng(-6.2088, 106.8456), // Jakarta default
    );
  }

  LocationRepository get _locationRepo => LocationRepository(ref.read(dioProvider));

  Future<void> loadNearbyLocations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locations = await _locationRepo.getNearbyLocations(
        lat: state.cameraPosition.latitude,
        lng: state.cameraPosition.longitude,
      );

      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat peta');
    }
  }

  void updateCameraPosition(LatLng position) {
    state = state.copyWith(cameraPosition: position);
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);

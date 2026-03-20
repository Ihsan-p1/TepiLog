import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/app/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  Location? _selectedLocation;

  final String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#1c1c1e" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#a1a1aa" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#1c1c1e" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#3f3f46" }] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{ "color": "#d6d3d1" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#27272a" }] },
  { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#3f3f46" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#000000" }] }
]
''';

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    // Build markers from locations
    final markers = mapState.locations.map((loc) {
      return Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.latitude, loc.longitude),
        infoWindow: InfoWindow(
          title: loc.name ?? 'Lokasi Tanpa Nama',
          snippet: '${loc.postCount} kiriman',
        ),
        onTap: () {
          setState(() => _selectedLocation = loc);
        },
      );
    }).toSet();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapState.cameraPosition,
              zoom: 15,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(_darkMapStyle);
              ref.read(mapProvider.notifier).loadNearbyLocations();
            },
            onCameraIdle: () {
              ref.read(mapProvider.notifier).loadNearbyLocations();
            },
            onCameraMove: (position) {
              ref.read(mapProvider.notifier).updateCameraPosition(position.target);
            },
            onTap: (_) {
              // Dismiss bottom sheet when tapping map
              setState(() => _selectedLocation = null);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'search locations...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Preview Bottom Sheet
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  context.pushNamed(
                    'location-detail',
                    pathParameters: {'id': _selectedLocation!.id},
                  ).then((_) {
                    ref.read(mapProvider.notifier).loadNearbyLocations();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Location name & post count
                      Text(
                        _selectedLocation!.name ?? 'Tanpa Nama',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation!.postCount} photos',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tap hint
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            'Ketuk untuk detail →',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

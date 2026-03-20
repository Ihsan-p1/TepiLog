import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/app/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;

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
          snippet: '${loc.postCount} kiriman • Klik untuk detail',
        ),
        onTap: () {
          context.pushNamed('location-detail', pathParameters: {'id': loc.id});
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
            onCameraMove: (position) {
              ref.read(mapProvider.notifier).updateCameraPosition(position.target);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Header / Search Bar Placeholder
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
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cari lokasi...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed('upload');
        },
        backgroundColor: AppTheme.textPrimary,
        foregroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Tepi Log'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tepilog/app/theme.dart';

/// Full-screen map picker for selecting upload coordinates.
/// Returns a LatLng via Navigator.pop when user confirms.
class TagOnMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const TagOnMapScreen({
    super.key,
    this.initialLat = -6.2088,
    this.initialLng = 106.8456,
  });

  @override
  State<TagOnMapScreen> createState() => _TagOnMapScreenState();
}

class _TagOnMapScreenState extends State<TagOnMapScreen> {
  late LatLng _selectedPosition;
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
  void initState() {
    super.initState();
    _selectedPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pilih Lokasi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedPosition),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(_darkMapStyle);
            },
            onTap: (LatLng position) {
              setState(() => _selectedPosition = position);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Coordinate info
          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Ketuk peta untuk pindahkan pin',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

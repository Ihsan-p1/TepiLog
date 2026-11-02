import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/map_styles.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/features/map/presentation/widgets/photo_pin.dart';
import 'package:tepilog/features/map/presentation/widgets/place_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Kept as an id and looked up in the latest list, so the card shows the
  // fresh count after an upload instead of a stale copy.
  String? _selectedId;

  static const _titleArea = 120.0;

  Set<Marker> _markers(List<Location> locations, Brightness brightness, double dpr) {
    final markers = <Marker>{};
    for (final loc in locations) {
      final url = loc.coverUrl;
      if (url == null) continue;
      final selected = loc.id == _selectedId;
      final icon = ref.watch(photoPinProvider((
        url: url,
        count: loc.postCount,
        selected: selected,
        brightness: brightness,
        devicePixelRatio: dpr,
      )));
      // Skip until the bitmap is ready rather than flash the default red pin.
      final bitmap = icon.value;
      if (bitmap == null) continue;
      final size = selected ? PhotoPinSize.selected : PhotoPinSize.normal;
      markers.add(Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.latitude, loc.longitude),
        icon: bitmap,
        anchor: size.anchor,
        zIndexInt: selected ? 1 : 0,
        // The title names the pin for TalkBack. consumeTapEvents stops the
        // map from opening the white info window on tap.
        infoWindow: InfoWindow(title: '${loc.name ?? 'Lokasi tanpa nama'}, ${placeLine(loc)}'),
        consumeTapEvents: true,
        onTap: () => setState(() => _selectedId = loc.id),
      ));
    }
    return markers;
  }

  void _open(Location loc) {
    context.pushNamed('location-detail', pathParameters: {'id': loc.id}).then((_) {
      ref.read(mapProvider.notifier).loadNearbyLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final brightness = theme.brightness;
    final selected = mapState.locations.where((l) => l.id == _selectedId).firstOrNull;

    // media.padding.bottom already holds the floating tab bar (extendBody).
    final bottomInset = media.padding.bottom + 12;
    final cardSpace = selected == null ? 0.0 : PlaceCard.height + 12;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: mapState.cameraPosition,
                zoom: 15,
              ),
              markers: _markers(mapState.locations, brightness, media.devicePixelRatio),
              style: brightness == Brightness.light ? kLightMapStyle : kDarkMapStyle,
              // Keeps the Google logo clear of the tab bar and the card.
              padding: EdgeInsets.only(
                top: media.padding.top + _titleArea,
                bottom: bottomInset + cardSpace,
              ),
              onMapCreated: (_) => ref.read(mapProvider.notifier).loadNearbyLocations(),
              onCameraIdle: () => ref.read(mapProvider.notifier).loadNearbyLocations(),
              onCameraMove: (position) =>
                  ref.read(mapProvider.notifier).updateCameraPosition(position.target),
              onTap: (_) => setState(() => _selectedId = null),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // Title over a fade of the ground colour so it reads on any map.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: mapState.error == null,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, media.padding.top + 16, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.55, 1],
                      colors: [
                        scheme.surface.withValues(alpha: 0.92),
                        scheme.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Peta', style: theme.textTheme.displaySmall),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mapCountLine(mapState),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mapState.error != null ? scheme.error : null,
                              ),
                            ),
                          ),
                          if (mapState.error != null)
                            TextButton(
                              onPressed: () =>
                                  ref.read(mapProvider.notifier).loadNearbyLocations(),
                              child: const Text('Coba lagi'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset,
              child: AnimatedSwitcher(
                duration: media.disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: selected == null
                    ? const SizedBox.shrink()
                    : PlaceCard(
                        key: ValueKey(selected.id),
                        location: selected,
                        onOpen: () => _open(selected),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

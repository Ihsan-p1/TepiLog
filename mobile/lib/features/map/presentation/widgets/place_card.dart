import 'package:flutter/material.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/providers/map_provider.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

/// "20 foto · 2019–2025": photo count and the years the photos span.
String placeLine(Location location) => fotoSpan(
      location.postCount,
      location.firstTakenAt?.toLocal().year,
      location.lastTakenAt?.toLocal().year,
    );

String fotoSpan(int count, int? firstYear, int? lastYear) {
  final photos = '$count foto';
  if (firstYear == null || lastYear == null) return photos;
  return firstYear == lastYear ? '$photos · $lastYear' : '$photos · $firstYear–$lastYear';
}

/// The line under the map title. Reloads on every camera move keep the old
/// count on screen instead of flashing the loading text.
String mapCountLine(MapState state) {
  if (state.error != null) return state.error!;
  if (state.locations.isEmpty) {
    return state.isLoading ? 'Memuat tempat…' : 'Belum ada foto di area ini';
  }
  return '${state.locations.length} tempat di area ini';
}

/// The selected place as its newest photo, floating above the tab bar.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.location, required this.onOpen});

  static const height = 168.0;

  final Location location;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = location.name ?? 'Lokasi tanpa nama';
    final radius = BorderRadius.circular(24);

    return Semantics(
      button: true,
      label: 'Buka $name, ${placeLine(location)}',
      excludeSemantics: true,
      onTap: onOpen,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.black,
            child: InkWell(
              onTap: onOpen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (location.coverUrl != null) TepiImage(location.coverUrl!),
                  // Bottom shade so white type reads on any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineSmall?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          placeLine(location),
                          style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  List<Location> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final repo = LocationRepository(ref.read(dioProvider));
      final locations = await repo.getTrendingLocations(
        lat: -6.2088,
        lng: 106.8456,
      );
      setState(() {
        _locations = locations;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Trending error: $e');
      // Fallback: show top locations by post count
      try {
        final repo = LocationRepository(ref.read(dioProvider));
        final locations = await repo.getNearbyLocations(
          lat: -6.2088,
          lng: 106.8456,
          radius: 50000,
        );
        locations.sort((a, b) => b.postCount.compareTo(a.postCount));
        setState(() {
          _locations = locations.take(20).toList();
          _loading = false;
        });
      } catch (_) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'trending nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '50 km',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _locations.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada lokasi trending',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Text(
                        'last 7 days · by activity',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          final loc = _locations[index];
                          return _TrendingItem(
                            rank: index + 1,
                            location: loc,
                            onTap: () => context.pushNamed(
                              'location-detail',
                              pathParameters: {'id': loc.id},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final int rank;
  final Location location;
  final VoidCallback onTap;

  const _TrendingItem({
    required this.rank,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : AppTheme.textSecondary,
                  fontSize: rank <= 3 ? 20 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Thumbnail placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: const Icon(Icons.photo, color: AppTheme.border, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name ?? 'Tanpa Nama',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.distance != null
                        ? '${(location.distance! / 1000).toStringAsFixed(0)} km'
                        : '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Post count
            Text(
              '${location.postCount} posts',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

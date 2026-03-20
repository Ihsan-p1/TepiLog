import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  final String locationId;

  const LocationDetailScreen({
    super.key,
    required this.locationId,
  });

  @override
  ConsumerState<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  Location? _location;
  List<PostModel> _posts = [];
  bool _loading = true;
  String? _nextCursor;
  bool _hasMore = false;
  double _sliderValue = 1.0;

  // Derived from actual post dates
  List<int> _years = [];
  List<PostModel> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = ref.read(dioProvider);
      final locRepo = LocationRepository(dio);
      final postRepo = PostRepository(dio);

      final location = await locRepo.getLocationDetail(widget.locationId);
      final feed = await postRepo.getPostsByLocation(locationId: widget.locationId, limit: 50);

      // Extract unique years from post dates
      final yearSet = <int>{};
      for (final p in feed.posts) {
        yearSet.add(p.takenAt.year);
      }
      final years = yearSet.toList()..sort();

      setState(() {
        _location = location;
        _posts = feed.posts;
        _nextCursor = feed.nextCursor;
        _hasMore = feed.hasMore;
        _years = years.isEmpty ? [DateTime.now().year] : years;
        _sliderValue = 1.0;
        _loading = false;
      });
      _filterPosts();
    } catch (e) {
      debugPrint('LocationDetail load error: $e');
      setState(() => _loading = false);
    }
  }

  void _filterPosts() {
    if (_years.isEmpty || _posts.isEmpty) {
      setState(() => _filteredPosts = _posts);
      return;
    }
    final selectedYear = _years[(_sliderValue * (_years.length - 1)).round()];
    setState(() {
      _filteredPosts = _posts.where((p) => p.takenAt.year == selectedYear).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final selectedYear = _years.isNotEmpty
        ? _years[(_sliderValue * (_years.length - 1)).round()]
        : DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Post grid or empty state
          Positioned.fill(
            child: _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 60, color: AppTheme.border),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada foto di lokasi ini',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.pushNamed('upload'),
                          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                          label: const Text('Jadilah yang pertama!'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Spacer for header
                      SliverToBoxAdapter(
                        child: SizedBox(height: MediaQuery.of(context).padding.top + 70),
                      ),
                      // Photo grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = _filteredPosts[index];
                              return GestureDetector(
                                onTap: () => context.pushNamed(
                                  'post-detail',
                                  pathParameters: {'id': post.id},
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      post.mediaUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: AppTheme.surface,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // EXIF date overlay
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          _formatShortDate(post.takenAt),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _filteredPosts.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                        ),
                      ),
                      // Bottom spacer for slider
                      const SliverToBoxAdapter(child: SizedBox(height: 180)),
                    ],
                  ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                right: 10,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _location?.name ?? 'Lokasi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_posts.length} kiriman',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timeline Slider
          if (_years.length > 1)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _years.first.toString(),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        Column(
                          children: [
                            Text(
                              selectedYear.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_filteredPosts.length} foto',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                        Text(
                          _years.last.toString(),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: (value) {
                          setState(() => _sliderValue = value);
                          _filterPosts();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

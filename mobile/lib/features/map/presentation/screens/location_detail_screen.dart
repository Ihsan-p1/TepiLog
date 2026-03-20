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
  double _sliderValue = 1.0;
  bool _sortRecent = true;

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

      final yearSet = <int>{};
      for (final p in feed.posts) {
        yearSet.add(p.takenAt.year);
      }
      final years = yearSet.toList()..sort();

      setState(() {
        _location = location;
        _posts = feed.posts;
        _years = years.isEmpty ? [DateTime.now().year] : years;
        _sliderValue = 1.0;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('LocationDetail error: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_years.isEmpty || _posts.isEmpty) {
      setState(() => _filteredPosts = _posts);
      return;
    }
    final selectedYear = _years[(_sliderValue * (_years.length - 1)).round()];
    var filtered = _posts.where((p) => p.takenAt.year == selectedYear).toList();

    if (_sortRecent) {
      filtered.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    } else {
      filtered.sort((a, b) => a.takenAt.compareTo(b.takenAt));
    }

    setState(() => _filteredPosts = filtered);
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _location?.name ?? 'Lokasi',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info bar: photo count + sort toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_posts.length} photos',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Sort toggle
                _SortToggle(
                  isRecent: _sortRecent,
                  onChanged: (recent) {
                    setState(() => _sortRecent = recent);
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),

          // Timeline slider
          if (_years.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _years.first.toString(),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: (value) {
                          setState(() => _sliderValue = value);
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                  const Text(
                    'now',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Card feed
          Expanded(
            child: _filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 48, color: AppTheme.border),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada foto',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = _filteredPosts[index];
                      return _PostCard(
                        post: post,
                        onTap: () => context.pushNamed(
                          'post-detail',
                          pathParameters: {'id': post.id},
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

// Sort toggle widget (recent / oldest)
class _SortToggle extends StatelessWidget {
  final bool isRecent;
  final ValueChanged<bool> onChanged;

  const _SortToggle({required this.isRecent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('recent', isRecent, () => onChanged(true)),
          _toggleItem('oldest', !isRecent, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Card-based post item
class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username + time ago
            if (post.user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Avatar circle
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.surface,
                      child: Text(
                        (post.user!.username[0]).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${post.user!.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _timeAgo(post.uploadedAt),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Photo with EXIF overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
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
                  ),
                  // EXIF tag
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'taken · ${_formatDate(post.takenAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Caption
            if (post.caption != null && post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  post.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month ago';
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    return '${diff.inMinutes} min ago';
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

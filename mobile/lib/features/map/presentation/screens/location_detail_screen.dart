import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/widgets/place_card.dart';
import 'package:tepilog/features/map/presentation/widgets/year_chapters.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/constants/api_constants.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';

/// A place's photos read as chapters, one per year, newest year first.
/// A place with photos from one year only goes straight to a grid.
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
  // ponytail: pages of 50, at most 20; a place past 1000 photos shows its newest 1000.
  static const _pageSize = 50;
  static const _maxPages = 20;

  final _scroll = ScrollController();
  Location? _location;
  List<YearChapter> _chapters = [];
  List<GlobalKey> _chapterKeys = [];
  bool _loading = true;
  bool _failed = false;
  bool _isSaved = false;
  int _active = 0;
  double _barHeight = 56;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final dio = ref.read(dioProvider);
      final postRepo = PostRepository(dio);
      final location = await LocationRepository(dio).getLocationDetail(widget.locationId);

      // Every page, so the oldest years get their chapters too.
      final posts = <PostModel>[];
      String? cursor;
      for (var page = 0; page < _maxPages; page++) {
        final feed = await postRepo.getPostsByLocation(
          locationId: widget.locationId,
          cursor: cursor,
          limit: _pageSize,
        );
        posts.addAll(feed.posts);
        cursor = feed.nextCursor;
        if (!feed.hasMore || cursor == null) break;
      }

      if (!mounted) return;
      final chapters = chaptersByYear(posts);
      setState(() {
        _location = location;
        _chapters = chapters;
        _chapterKeys = [for (final _ in chapters) GlobalKey()];
        _active = 0;
        _loading = false;
      });
      _checkSaved();
    } catch (e) {
      debugPrint('LocationDetail error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _checkSaved() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('${ApiConstants.saved}/${widget.locationId}/check');
      if (mounted) setState(() => _isSaved = res.data['saved'] == true);
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('${ApiConstants.saved}/${widget.locationId}');
      if (mounted) setState(() => _isSaved = res.data['saved'] == true);
    } catch (_) {}
  }

  void _openPost(PostModel post) =>
      context.pushNamed('post-detail', pathParameters: {'id': post.id});

  /// Scroll offset that puts chapter [i] just under the sticky year bar.
  double? _offsetOf(int i) {
    final box = _chapterKeys[i].currentContext?.findRenderObject();
    if (box == null) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset - _barHeight;
  }

  bool _followScroll(ScrollNotification n) {
    if (_chapters.length < 2 || n.depth != 0) return false;
    // A chapter counts as being read once its top passes 40% of the screen.
    final line = _scroll.offset + _scroll.position.viewportDimension * 0.4;
    var active = 0;
    for (var i = 0; i < _chapters.length; i++) {
      final offset = _offsetOf(i);
      if (offset != null && offset <= line) active = i;
    }
    // The last chapter is often too short to reach the bar; at the bottom
    // of the page it is the one being read.
    if (_scroll.offset >= _scroll.position.maxScrollExtent - 1) active = _chapters.length - 1;
    if (active != _active) setState(() => _active = active);
    return false;
  }

  void _jumpTo(int i) {
    final offset = _offsetOf(i);
    if (offset == null) return;
    setState(() => _active = i);
    final target = offset.clamp(0.0, _scroll.position.maxScrollExtent);
    if (MediaQuery.of(context).disableAnimations) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.onSurfaceVariant))
              : _failed
                  ? _failure(theme)
                  : _content(theme),
        ),
      ),
    );
  }

  Widget _topButtons() {
    final scheme = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      backgroundColor: scheme.surfaceContainer,
      foregroundColor: scheme.onSurface,
    );
    return Row(
      children: [
        IconButton(
          tooltip: 'Kembali',
          style: style,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        if (!_failed)
          IconButton(
            tooltip: _isSaved ? 'Hapus dari simpanan' : 'Simpan lokasi',
            style: style,
            icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 20),
            onPressed: _toggleSave,
          ),
      ],
    );
  }

  Widget _failure(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          _topButtons(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tempat ini gagal dimuat.', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Periksa koneksi, lalu coba lagi.', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                TextButton(onPressed: _loadData, child: const Text('Coba lagi')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final scheme = theme.colorScheme;
    final accents = [
      for (final c in _chapters)
        ref.watch(photoSchemeProvider((c.posts.first.mediaUrl, theme.brightness))).value?.primary ??
            scheme.onSurface,
    ];
    final postCount = _chapters.fold(0, (n, c) => n + c.posts.length);
    final bottom = MediaQuery.of(context).padding.bottom + 32;
    _barHeight = YearBar.heightOf(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _followScroll,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topButtons(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            _location?.name ?? 'Lokasi tanpa nama',
                            style: theme.textTheme.displaySmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fotoSpan(
                            postCount,
                            _chapters.lastOrNull?.year,
                            _chapters.firstOrNull?.year,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_chapters.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Belum ada foto di tempat ini.', style: theme.textTheme.bodySmall),
              ),
            )
          else if (_chapters.length == 1) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: ChapterTitle(chapter: _chapters.single, accent: accents.single, asChapter: false),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final post in _chapters.single.posts)
                    PhotoTile(post: post, radius: 8, onTap: () => _openPost(post)),
                ],
              ),
            ),
          ] else ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _YearBarDelegate(
                YearBar(chapters: _chapters, active: _active, accents: accents, onSelect: _jumpTo),
                _barHeight,
              ),
            ),
            // A Column, not a lazy list: the year bar needs every chapter laid
            // out to scroll to it. Places have a handful of years.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  for (final (i, chapter) in _chapters.indexed)
                    Padding(
                      key: _chapterKeys[i],
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 24),
                      child: YearChapterView(chapter: chapter, accent: accents[i], onOpen: _openPost),
                    ),
                ],
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }
}

class _YearBarDelegate extends SliverPersistentHeaderDelegate {
  _YearBarDelegate(this.bar, this.height);

  final YearBar bar;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Once photos slide under the pinned bar, a short fade below it hides
    // the cut edge of the photo underneath. The pinned header paints above
    // the content, so the fade may hang below its own extent.
    final ground = Theme.of(context).colorScheme.surface;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: bar),
        if (overlapsContent)
          Positioned(
            left: 0,
            right: 0,
            bottom: -12,
            height: 12,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ground, ground.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(_YearBarDelegate old) => true;
}

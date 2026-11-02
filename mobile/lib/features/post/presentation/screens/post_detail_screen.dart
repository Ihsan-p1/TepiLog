import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/features/post/presentation/widgets/comment_section.dart';
import 'package:tepilog/features/post/presentation/widgets/photo_pager.dart';
import 'package:tepilog/shared/constants/api_constants.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';

/// One photo, with every other photo of the same place a swipe away in
/// time order (oldest left, newest right). Who posted it, its caption and
/// its comments follow the photo in view.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

const _gutter = 24.0;

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  PageController? _pages;
  List<PostModel> _posts = [];
  String? _placeName;
  int _index = 0;
  bool _loading = true;
  bool _failed = false;
  bool _sending = false;

  /// Raw API comments per photo, newest first; null while loading, absent
  /// when loading failed.
  final _comments = <String, List<dynamic>?>{};

  PostModel get _current => _posts[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pages?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repo = PostRepository(ref.read(dioProvider));
      final opened = await repo.getPostDetail(widget.postId);
      final posts = await repo.getAllPostsByLocation(opened.locationId);
      if (!posts.any((p) => p.id == opened.id)) posts.add(opened);
      posts.sort((a, b) => a.takenAt.compareTo(b.takenAt));
      final index = posts.indexWhere((p) => p.id == opened.id);

      if (!mounted) return;
      _pages?.dispose();
      setState(() {
        _posts = posts;
        _placeName = opened.location?.name;
        _index = index;
        // Photo edges on the 24 dp text gutter; neighbours peek in by 14 dp.
        final width = MediaQuery.sizeOf(context).width;
        _pages = PageController(initialPage: index, viewportFraction: 1 - 38 / width);
        _loading = false;
      });
      _loadComments(opened.id);
    } catch (e) {
      debugPrint('Post detail error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _loadComments(String postId) async {
    if (_comments.containsKey(postId)) return;
    _comments[postId] = null;
    try {
      final res = await ref.read(dioProvider).get('${ApiConstants.comments}/$postId');
      if (mounted) setState(() => _comments[postId] = res.data as List<dynamic>);
    } catch (_) {
      if (mounted) setState(() => _comments.remove(postId));
    }
  }

  void _onPage(int i) {
    setState(() => _index = i);
    _loadComments(_posts[i].id);
  }

  Future<void> _send() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _sending) return;
    final postId = _current.id;

    setState(() => _sending = true);
    try {
      final res = await ref.read(dioProvider).post(
            '${ApiConstants.comments}/$postId',
            data: {'body': body},
          );
      if (!mounted) return;
      setState(() {
        _comments[postId] = [res.data, ...?_comments[postId]];
        _commentController.clear();
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar belum terkirim. Coba lagi.')),
      );
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Kembali',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainer,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: theme.colorScheme.onSurfaceVariant),
                      )
                    : _failed
                        ? _failure(theme)
                        : _content(theme),
              ),
              if (!_loading && !_failed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 8),
                  child: CommentInput(
                    controller: _commentController,
                    sending: _sending,
                    onSend: _send,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failure(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Foto ini gagal dimuat.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Periksa koneksi, lalu coba lagi.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final post = _current;
    final accent = ref
            .watch(photoSchemeProvider((post.mediaUrl, theme.brightness)))
            .value
            ?.primary ??
        scheme.onSurface;
    final comments = _comments[post.id];
    final loadingComments = _comments.containsKey(post.id) && comments == null;
    final username = post.user?.username ?? 'pengguna';
    final caption = post.caption;

    return LayoutBuilder(builder: (context, box) {
      // Square frame: fair to landscape and portrait photos alike, and
      // shorter on small screens so the comments still show.
      final photoSize = (box.maxWidth - 2 * _gutter).clamp(0.0, box.maxHeight * 0.62);

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: photoSize,
            child: PhotoPager(
              posts: _posts,
              current: _index,
              controller: _pages!,
              onPageChanged: _onPage,
            ),
          ),
          const SizedBox(height: 12),
          PageDots(count: _posts.length, index: _index, accent: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.surfaceContainerHigh,
                        child: Text(
                          username.isEmpty ? '?' : username[0].toUpperCase(),
                          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@$username', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text('diunggah ${formatDay(post.uploadedAt)}', style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_placeName != null) ...[
                  const SizedBox(height: 10),
                  // On the username's column, dot beside the name: a label,
                  // not a button.
                  Row(
                    children: [
                      const SizedBox(width: 46),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _placeName!,
                          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
                if (caption != null && caption.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(caption, style: text.bodyMedium?.copyWith(height: 1.45)),
                ],
                const SizedBox(height: 24),
                if (comments != null && comments.isNotEmpty) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      '${comments.length} komentar',
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (comments == null && !loadingComments)
                  Text('Komentar gagal dimuat.', style: text.bodySmall),
                if (comments != null) CommentList(comments: comments),
              ],
            ),
          ),
        ],
      );
    });
  }
}

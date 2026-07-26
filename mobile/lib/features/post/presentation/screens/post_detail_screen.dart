import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/constants/api_constants.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  PostModel? _post;
  List<dynamic> _comments = [];
  bool _loading = true;
  final _commentController = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final dio = ref.read(dioProvider);
      final repo = PostRepository(dio);
      final post = await repo.getPostDetail(widget.postId);

      // Load comments
      final commentsRes = await dio.get('${ApiConstants.comments}/${widget.postId}');

      setState(() {
        _post = post;
        _comments = commentsRes.data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Post detail error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _postComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _postingComment = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '${ApiConstants.comments}/${widget.postId}',
        data: {'body': body},
      );

      setState(() {
        _comments.insert(0, res.data);
        _commentController.clear();
        _postingComment = false;
      });
    } catch (e) {
      setState(() => _postingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim komentar'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(
          child: Text('Post tidak ditemukan', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final post = _post!;
    final username = post.user?.username ?? 'user';
    final locationName = post.location?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@$username', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (locationName.isNotEmpty)
              Text(locationName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        titleSpacing: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),

                  // EXIF badge bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: AppTheme.surface,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'taken · ${_formatDate(post.takenAt)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Location + Caption
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locationName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              locationName,
                              style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (post.caption != null && post.caption!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              post.caption!,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                            ),
                          ),

                        // Comments header
                        Text(
                          '${_comments.length} comments',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // Comments list
                        if (_comments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Belum ada komentar. Jadilah yang pertama!',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...(_comments.map((c) => _CommentCard(comment: c)).toList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _postingComment ? null : _postComment,
                  icon: _postingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}

class _CommentCard extends StatelessWidget {
  final dynamic comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final user = comment['user'];
    final username = user?['username'] ?? 'user';
    final body = comment['body'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

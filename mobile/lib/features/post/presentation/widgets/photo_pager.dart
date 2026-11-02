import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "28 Mei 2025" in local time.
String formatDay(DateTime dt) {
  final t = dt.toLocal();
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}

/// "08.34 WIB": Indonesian time with a dot. The zone name is shown only when
/// the device gives a short one (WIB, WITA, WIT).
String _clock(DateTime dt) {
  final t = dt.toLocal();
  final hm = '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
  final zone = t.timeZoneName;
  return RegExp(r'^[A-Z]{2,5}$').hasMatch(zone) ? '$hm $zone' : hm;
}

/// The photos of one place in time order, swiped sideways. Neighbours peek
/// in at the edges, dimmed and set back; the capture time rides on top.
class PhotoPager extends StatelessWidget {
  const PhotoPager({
    super.key,
    required this.posts,
    required this.current,
    required this.controller,
    required this.onPageChanged,
  });

  final List<PostModel> posts;
  final int current;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: posts.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, i) {
        final photo = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _Photo(post: posts[i], position: i + 1, count: posts.length),
        );
        return AnimatedBuilder(
          animation: controller,
          // Only the photo in view is read out; the peeking ones are not.
          child: i == current ? photo : ExcludeSemantics(child: photo),
          builder: (context, child) {
            final page = controller.hasClients && controller.position.haveDimensions
                ? controller.page ?? current.toDouble()
                : current.toDouble();
            final away = (page - i).abs().clamp(0.0, 1.0);
            // Shrink toward the photo in view, so the peeking edge stays put.
            return Opacity(
              opacity: 1 - 0.4 * away,
              child: Transform.scale(
                scale: 1 - 0.06 * away,
                alignment: i > page ? Alignment.centerLeft : Alignment.centerRight,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.post, required this.position, required this.count});

  final PostModel post;
  final int position;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Foto $position dari $count, diambil ${formatDay(post.takenAt)} pukul ${_clock(post.takenAt)}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHigh),
            TepiImage(post.mediaUrl),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Center(
                // Capped at 1.5x (21 sp): larger, the pill would cover the photo.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.5,
                  child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xB3111214),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Text(
                        'Diambil ${formatDay(post.takenAt)} pukul ${_clock(post.takenAt)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _dotWindow = 7;

/// First dot shown when [index] is open, given the window's previous start:
/// the window holds still and slides only when the open dot reaches an edge,
/// so the dots visibly move as the user swipes.
int dotWindowStart(int previousStart, int index, int count) {
  if (count <= _dotWindow) return 0;
  var start = previousStart.clamp(0, count - _dotWindow);
  if (index <= start) start = math.max(0, index - 1);
  if (index >= start + _dotWindow - 1) start = math.min(count - _dotWindow, index - (_dotWindow - 2));
  return start;
}

/// Where the open photo sits among the place's photos: at most seven dots,
/// the open one long and in the photo's colour. Edge dots shrink when more
/// photos lie beyond them. The photo itself tells screen readers its place.
class PageDots extends StatefulWidget {
  const PageDots({super.key, required this.count, required this.index, required this.accent});

  final int count;
  final int index;
  final Color accent;

  @override
  State<PageDots> createState() => _PageDotsState();
}

class _PageDotsState extends State<PageDots> {
  late int _start = dotWindowStart(widget.index - _dotWindow ~/ 2, widget.index, widget.count);

  @override
  void didUpdateWidget(PageDots old) {
    super.didUpdateWidget(old);
    _start = dotWindowStart(_start, widget.index, widget.count);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final end = math.min(widget.count, _start + _dotWindow);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = _start; i < end; i++)
            () {
              final open = i == widget.index;
              final edge = (i == _start && _start > 0) || (i == end - 1 && end < widget.count);
              final size = edge && !open ? 4.0 : 7.0;
              return AnimatedContainer(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: open ? 18 : size,
                height: size,
                decoration: BoxDecoration(
                  color: open ? widget.accent : muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// One year of a place's photos, newest photo first.
class YearChapter {
  YearChapter(this.year, this.posts);

  final int year;
  final List<PostModel> posts;

  /// "Mei–Agu · 8 foto": the months the year's photos span and their count.
  String get line {
    final months = posts.map((p) => p.takenAt.month).toSet().toList()..sort();
    final span = months.length == 1
        ? _months[months.first - 1]
        : '${_months[months.first - 1]}–${_months[months.last - 1]}';
    return '$span · ${posts.length} foto';
  }
}

/// Groups photos into chapters by capture year (local time), newest first.
List<YearChapter> chaptersByYear(List<PostModel> posts) {
  final sorted = [...posts]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  final chapters = <YearChapter>[];
  for (final post in sorted) {
    if (chapters.isEmpty || chapters.last.year != post.takenAt.year) {
      chapters.add(YearChapter(post.takenAt.year, []));
    }
    chapters.last.posts.add(post);
  }
  return chapters;
}

/// "2025 ● Mei · 8 foto". [asChapter] names it a chapter heading for
/// screen readers; a single-year place has no chapters to move between.
class ChapterTitle extends StatelessWidget {
  const ChapterTitle({
    super.key,
    required this.chapter,
    required this.accent,
    this.asChapter = true,
  });

  final YearChapter chapter;
  final Color accent;
  final bool asChapter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final year = Text(
      '${chapter.year}',
      style: text.headlineSmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        asChapter
            ? Semantics(header: true, label: 'Bab ${chapter.year}', child: ExcludeSemantics(child: year))
            : year,
        const SizedBox(width: 10),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(chapter.line, style: text.bodySmall)),
      ],
    );
  }
}

/// A year as a chapter: its newest photo as the cover, the year under it,
/// then the rest of the year in a row that runs off the right edge.
class YearChapterView extends StatelessWidget {
  const YearChapterView({
    super.key,
    required this.chapter,
    required this.accent,
    required this.onOpen,
  });

  final YearChapter chapter;
  final Color accent;
  final ValueChanged<PostModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final cover = chapter.posts.first;
    final rest = chapter.posts.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PhotoTile(
            post: cover,
            radius: 24,
            aspectRatio: 4 / 3,
            shadow: true,
            onTap: () => onOpen(cover),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ChapterTitle(chapter: chapter, accent: accent),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rest.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(
                width: 96,
                child: PhotoTile(post: rest[i], radius: 16, onTap: () => onOpen(rest[i])),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A photo that opens on tap; named by its capture date for screen readers.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.post,
    required this.radius,
    required this.onTap,
    this.aspectRatio = 1,
    this.shadow = false,
  });

  final PostModel post;
  final double radius;
  final VoidCallback onTap;
  final double aspectRatio;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final t = post.takenAt;
    final shape = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      label: 'Foto ${t.day} ${_months[t.month - 1]} ${t.year}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            boxShadow: shadow
                ? const [BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 10))]
                : null,
          ),
          child: ClipRRect(
            borderRadius: shape,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Ink.image(
                image: tepiImageProvider(post.mediaUrl),
                fit: BoxFit.cover,
                child: InkWell(onTap: onTap),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky row of years; the chip of the chapter in view is filled with that
/// chapter's photo colour.
class YearBar extends StatelessWidget {
  const YearBar({
    super.key,
    required this.chapters,
    required this.active,
    required this.accents,
    required this.onSelect,
  });

  static const height = 64.0;

  final List<YearChapter> chapters;
  final int active;
  final List<Color> accents;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chapters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final selected = i == active;
          final fill = selected ? accents[i] : scheme.surfaceContainerHigh;
          final ink = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
              ? Colors.white
              : const Color(0xFF111214);
          return Semantics(
            button: true,
            selected: selected,
            label: 'Tahun ${chapters[i].year}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${chapters[i].year}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

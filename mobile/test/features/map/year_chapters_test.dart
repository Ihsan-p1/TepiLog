import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/map/presentation/widgets/year_chapters.dart';
import 'package:tepilog/features/post/data/post_repository.dart';

PostModel _post(String id, DateTime takenAt) => PostModel(
      id: id,
      mediaUrl: 'asset:assets/demo/prau/prau-01.jpg',
      mediaType: 'photo',
      takenAt: takenAt,
      uploadedAt: takenAt,
      userId: 'u',
      locationId: 'l',
    );

void main() {
  test('chapters run newest year first, photos newest first', () {
    final chapters = chaptersByYear([
      _post('a', DateTime(2019, 8, 17)),
      _post('b', DateTime(2025, 5, 28, 8)),
      _post('c', DateTime(2025, 8, 1)),
      _post('d', DateTime(2019, 8, 18)),
    ]);

    expect(chapters.map((c) => c.year), [2025, 2019]);
    expect(chapters.first.posts.map((p) => p.id), ['c', 'b']);
    expect(chapters.last.posts.map((p) => p.id), ['d', 'a']);
  });

  test('chapter line names its months and photo count', () {
    final chapters = chaptersByYear([
      _post('a', DateTime(2019, 8, 17)),
      _post('b', DateTime(2025, 5, 28)),
      _post('c', DateTime(2025, 8, 1)),
      _post('d', DateTime(2025, 5, 2)),
    ]);

    expect(chapters.first.line, 'Mei–Agu · 3 foto');
    expect(chapters.last.line, 'Agu · 1 foto');
  });

  test('no photos gives no chapters', () {
    expect(chaptersByYear([]), isEmpty);
  });
}

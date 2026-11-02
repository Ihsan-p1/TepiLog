import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/main_shell.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/map/presentation/widgets/place_card.dart';
import 'package:tepilog/features/map/presentation/widgets/year_chapters.dart';
import 'package:tepilog/features/post/data/post_repository.dart';

class _NoDemo extends DemoModeNotifier {
  @override
  bool build() => false;
}

final _post = PostModel(
  id: 'a',
  mediaUrl: 'asset:assets/demo/prau/prau-01.jpg',
  mediaType: 'photo',
  takenAt: DateTime(2025, 5, 28),
  uploadedAt: DateTime(2025, 6, 1),
  userId: 'u',
  locationId: 'l',
);

/// TalkBack activates a control through its semantics tap action. A label
/// wrapper that excludes its child's semantics must carry the action itself.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(ProviderScope(
        overrides: [demoModeProvider.overrideWith(_NoDemo.new)],
        child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
      ));

  testWidgets('tab bar items', (tester) async {
    await pump(tester, MainShell(currentIndex: 0, onTabChanged: (_) {}, child: const SizedBox()));
    expect(tester.getSemantics(find.bySemanticsLabel('Saya')), containsSemantics(hasTapAction: true));
  });

  testWidgets('place card', (tester) async {
    final place = Location(id: 'p', name: 'Gunung Prau', latitude: 0, longitude: 0, postCount: 1);
    await pump(tester, PlaceCard(location: place, onOpen: () {}));
    expect(tester.getSemantics(find.bySemanticsLabel(RegExp('^Buka'))), containsSemantics(hasTapAction: true));
  });

  testWidgets('photo tile', (tester) async {
    await pump(tester, SizedBox(width: 90, child: PhotoTile(post: _post, radius: 8, onTap: () {})));
    expect(tester.getSemantics(find.bySemanticsLabel(RegExp('^Foto'))), containsSemantics(hasTapAction: true));
  });

  testWidgets('year chip', (tester) async {
    final chapters = chaptersByYear([_post]);
    await pump(tester, SizedBox(
      height: 56,
      child: YearBar(chapters: chapters, active: 0, accents: const [Colors.blue], onSelect: (_) {}),
    ));
    expect(tester.getSemantics(find.bySemanticsLabel('Tahun 2025')), containsSemantics(hasTapAction: true));
  });
}

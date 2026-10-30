import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/main_shell.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

class _FixedDemoMode extends DemoModeNotifier {
  _FixedDemoMode(this.value);
  final bool value;

  @override
  bool build() => value;
}

Finder _imageWhere(bool Function(ImageProvider p) test) =>
    find.byWidgetPredicate((w) => w is Image && test(w.image));

void main() {
  Future<void> pumpImage(WidgetTester tester, String url) =>
      tester.pumpWidget(MaterialApp(home: TepiImage(url)));

  testWidgets('asset url renders Image.asset', (tester) async {
    await pumpImage(tester, 'asset:assets/demo/prau/prau-01.jpg');
    expect(_imageWhere((p) => p is AssetImage), findsOneWidget);
  });

  testWidgets('file url renders Image.file', (tester) async {
    await pumpImage(tester, 'file:/tmp/demo_uploads/x.jpg');
    expect(_imageWhere((p) => p is FileImage), findsOneWidget);
  });

  testWidgets('http url renders Image.network', (tester) async {
    await pumpImage(tester, 'https://res.cloudinary.com/x/image/upload/a.jpg');
    expect(_imageWhere((p) => p is NetworkImage), findsOneWidget);
    // The test HTTP client answers every request with 400; that is expected here.
    await tester.pump();
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('shell shows the demo banner only in demo mode', (tester) async {
    Future<void> pumpShell(bool demo) => tester.pumpWidget(ProviderScope(
          key: ValueKey(demo),
          overrides: [demoModeProvider.overrideWith(() => _FixedDemoMode(demo))],
          child: MaterialApp(
            home: MainShell(
              currentIndex: 0,
              onTabChanged: (_) {},
              child: const SizedBox(),
            ),
          ),
        ));
    const banner = 'Mode demo · data lokal · foto © Tomorrow';

    await pumpShell(true);
    expect(find.text(banner), findsOneWidget);

    await pumpShell(false);
    expect(find.text(banner), findsNothing);
  });
}

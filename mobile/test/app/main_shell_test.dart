import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/main_shell.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';

class _Demo extends DemoModeNotifier {
  _Demo(this.on);
  final bool on;

  @override
  bool build() => on;
}

void main() {
  late List<int> taps;

  Future<void> pumpShell(WidgetTester tester, int index, {bool demo = false}) {
    taps = [];
    return tester.pumpWidget(ProviderScope(
      overrides: [demoModeProvider.overrideWith(() => _Demo(demo))],
      child: MaterialApp(
        theme: AppTheme.light,
        home: MainShell(
          currentIndex: index,
          onTabChanged: taps.add,
          child: const SizedBox.expand(),
        ),
      ),
    ));
  }

  testWidgets('only the open tab shows its label', (tester) async {
    await pumpShell(tester, 1);

    expect(find.text('Ramai'), findsOneWidget);
    for (final other in ['Peta', 'Unggah', 'Saya']) {
      expect(find.text(other), findsNothing);
    }
  });

  testWidgets('every tab is named for screen readers and reports its index',
      (tester) async {
    await pumpShell(tester, 0);

    for (final label in ['Peta', 'Ramai', 'Unggah', 'Saya']) {
      await tester.tap(find.bySemanticsLabel(label));
    }
    expect(taps, [0, 1, 2, 3]);
  });

  testWidgets('tabs are at least 48 dp', (tester) async {
    await pumpShell(tester, 0);

    final size = tester.getSize(find.bySemanticsLabel('Saya'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('demo mode keeps the photo credit on screen', (tester) async {
    await pumpShell(tester, 0, demo: true);

    expect(find.textContaining('foto © Tomorrow'), findsOneWidget);
  });
}

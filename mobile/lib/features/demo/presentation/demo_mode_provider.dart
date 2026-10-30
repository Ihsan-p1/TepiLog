import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';

/// Gunung Prau summit, where the demo seed lives. The map opens here in demo mode.
const kDemoCenter = LatLng(-7.1867, 109.9228);

/// Overridden in main() once the Hive box is open.
final demoStoreProvider = Provider<DemoStore>(
  (ref) => throw UnimplementedError('demoStoreProvider must be overridden'),
);

final demoModeProvider =
    NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(demoStoreProvider).isActive;

  Future<void> enter() async {
    final store = ref.read(demoStoreProvider);
    await store.ensureSeeded();
    await store.setActive(true);
    state = true;
  }

  /// Leaves demo mode and throws away everything made during the demo.
  Future<void> exit() async {
    final store = ref.read(demoStoreProvider);
    await store.reset();
    await store.setActive(false);
    state = false;
  }
}

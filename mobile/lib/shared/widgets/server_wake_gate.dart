import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/shared/providers/server_status_provider.dart';

/// Shows the app while the backend answers, and a wait screen while a
/// sleeping backend wakes up. Demo mode skips the server entirely.
class ServerWakeGate extends ConsumerWidget {
  const ServerWakeGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void enterDemo() => ref.read(authProvider.notifier).enterDemo();

    return switch (ref.watch(serverStatusProvider)) {
      ServerStatus.checking || ServerStatus.ready => child,
      ServerStatus.waking => _GateScreen(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Server sedang bangun, biasanya sekitar 1 menit',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const _ElapsedSeconds(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: enterDemo,
              child: const Text('Coba demo sambil menunggu'),
            ),
          ],
        ),
      ServerStatus.failed => _GateScreen(
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 24),
            const Text(
              'Server tidak bisa dihubungi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: ref.read(serverStatusProvider.notifier).check,
              child: const Text('Coba lagi'),
            ),
            // Without a server the login screen is unreachable, so demo
            // has to be offered here too.
            TextButton(
              onPressed: enterDemo,
              child: const Text('Coba demo'),
            ),
          ],
        ),
    };
  }
}

class _GateScreen extends StatelessWidget {
  const _GateScreen({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _ElapsedSeconds extends StatefulWidget {
  const _ElapsedSeconds();

  @override
  State<_ElapsedSeconds> createState() => _ElapsedSecondsState();
}

class _ElapsedSecondsState extends State<_ElapsedSeconds> {
  late final Timer _timer;
  // The screen appears after the first 3 s of waiting.
  int _seconds = kWakeScreenDelay.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('$_seconds detik');
}

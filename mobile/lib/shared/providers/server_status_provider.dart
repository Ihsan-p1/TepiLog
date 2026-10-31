import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/shared/constants/api_constants.dart';

enum ServerStatus { checking, waking, ready, failed }

/// How long a reply may take before the wake screen shows.
const kWakeScreenDelay = Duration(seconds: 3);

/// A sleeping free-tier backend takes about a minute; give up after this.
const kWakeTimeout = Duration(seconds: 90);

/// Pings the backend health route. Own Dio, so no auth interceptor and no
/// demo interceptor, with timeouts long enough for a cold start.
final healthPingProvider = Provider<Future<void> Function()>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: kWakeTimeout,
    receiveTimeout: kWakeTimeout,
  ));
  return () => dio.get<void>(ApiConstants.health);
});

final serverStatusProvider =
    NotifierProvider<ServerStatusNotifier, ServerStatus>(
        ServerStatusNotifier.new);

class ServerStatusNotifier extends Notifier<ServerStatus> {
  // Each check gets a number; a reply from an older check is ignored.
  int _run = 0;

  @override
  ServerStatus build() {
    _run++;
    // Demo mode never needs the server.
    if (ref.watch(demoModeProvider)) return ServerStatus.ready;
    Future.microtask(check);
    return ServerStatus.checking;
  }

  Future<void> check() async {
    if (!ref.mounted) return;
    final run = ++_run;
    bool current() => ref.mounted && run == _run;

    state = ServerStatus.checking;
    final slow = Timer(kWakeScreenDelay, () {
      if (current() && state == ServerStatus.checking) {
        state = ServerStatus.waking;
      }
    });

    ServerStatus result;
    try {
      await ref.read(healthPingProvider)().timeout(kWakeTimeout);
      result = ServerStatus.ready;
    } catch (_) {
      // Refused connection, DNS failure, HTTP error or timeout: all mean the
      // app cannot use the server right now.
      result = ServerStatus.failed;
    }
    slow.cancel();
    if (current()) state = result;
  }
}

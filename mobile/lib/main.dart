import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tepilog/app/router.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/auth/presentation/providers/auth_provider.dart';
import 'package:tepilog/features/demo/data/demo_store.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Offline demo data, kept in its own Hive box
  final docs = await getApplicationDocumentsDirectory();
  final demoStore = DemoStore(
    box: await Hive.openBox('demo'),
    loadSeed: () async => jsonDecode(
        await rootBundle.loadString('assets/demo/seed.json')) as Map<String, dynamic>,
    uploadsDir: () async => Directory('${docs.path}/demo_uploads'),
  );

  // Create container and initialize token storage
  final container = ProviderContainer(
    overrides: [demoStoreProvider.overrideWithValue(demoStore)],
  );
  final tokenStorage = container.read(tokenStorageProvider);
  await tokenStorage.init();

  // Check existing auth
  await container.read(authProvider.notifier).checkAuth();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TepiLogApp(),
    ),
  );
}

class TepiLogApp extends ConsumerWidget {
  const TepiLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TepiLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

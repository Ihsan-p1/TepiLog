import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';

class MainShell extends ConsumerWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTabChanged;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoModeProvider);
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (demo)
            Container(
              width: double.infinity,
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'Mode demo · data lokal · foto © Tomorrow',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTabChanged,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.primary,
              selectedItemColor: Colors.white,
              unselectedItemColor: AppTheme.textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 22,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star_border_rounded),
                  activeIcon: Icon(Icons.star_rounded),
                  label: 'trending',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.file_upload_outlined),
                  activeIcon: Icon(Icons.file_upload_rounded),
                  label: 'upload',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
